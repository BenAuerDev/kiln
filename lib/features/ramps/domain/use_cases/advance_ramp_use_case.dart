import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../portable/domain/extensions/portable_status_x.dart';
import '../../../portable/domain/models/heater_mode.dart';
import '../../../portable/domain/repositories/portable_repository.dart';
import '../models/ramp_run.dart';
import '../repositories/ramp_run_repository.dart';
import '../services/ramp_service.dart';

/// One tick of the running ramp: writes the next base temperature when it
/// is due. While boosting, target writes are blocked, so a due step waits
/// until boost ends.
///
/// Acts only on a fresh status: in the background polling pauses and the
/// status stops updating, so the ramp waits instead of writing blind.
///
/// The ramp stops when the device changes or drops, the heater stays off
/// for [heaterOffGrace], or the base was changed by hand.
///
/// Callers run it through `RampRunRepository.serialized`.
class AdvanceRampUseCase {
  AdvanceRampUseCase({
    RampRunRepository? runs,
    PortableRepository? portable,
    ConnectionRepository? connection,
    RampService? ramps,
    DateTime Function()? clock,
  }) : _runs = runs ?? sl<RampRunRepository>(),
       _portable = portable ?? sl<PortableRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _ramps = ramps ?? sl<RampService>(),
       _clock = clock ?? DateTime.now;

  /// A status older than this is stale (the poll runs every 500 ms).
  static const freshFor = Duration(seconds: 2);

  /// Stale this long (kiln in the background, a hanging link) ends the ramp:
  /// it does not pick up a session the user may have restarted meanwhile.
  static const maxStale = Duration(minutes: 2);

  /// Ending boost from kiln is "heater off, then on"; an off this short is
  /// not the user switching the device off.
  static const heaterOffGrace = Duration(seconds: 3);

  /// A step later than this is rescheduled from now, so the next one keeps
  /// its full interval.
  static const _lateAfter = Duration(seconds: 5);

  final RampRunRepository _runs;
  final PortableRepository _portable;
  final ConnectionRepository _connection;
  final RampService _ramps;
  final DateTime Function() _clock;

  Future<Either<AppError, Unit>> call() async {
    var run = _runs.run.value;
    if (run == null || !run.isActive) return right(unit);
    final status = _portable.status.value;
    if (_connection.activeDeviceId.value != run.deviceId ||
        status == null ||
        _portable.sessionNumber.value != run.session) {
      _runs.end(run.copyWith(phase: RampRunPhase.stopped));
      return right(unit);
    }
    final now = _clock();
    final updatedAt = _portable.statusUpdatedAt.value;
    if (updatedAt == null || now.difference(updatedAt) > freshFor) {
      // Stale since the last step at the latest: kiln acted on it then.
      final staleSince = updatedAt ?? now;
      if (now.difference(staleSince) > maxStale) {
        _runs.end(run.copyWith(phase: RampRunPhase.stopped));
      }
      return right(unit);
    }

    if (status.heaterMode == HeaterMode.off) {
      final since = run.heaterOffSince ?? now;
      if (now.difference(since) >= heaterOffGrace) {
        _runs.end(run.copyWith(phase: RampRunPhase.stopped));
      } else if (run.heaterOffSince == null) {
        _runs.update(run.copyWith(heaterOffSince: now));
      }
      return right(unit);
    }
    if (run.heaterOffSince != null) {
      run = run.copyWith(clearHeaterOffSince: true);
      _runs.update(run);
    }

    final boosting = status.boostActive;
    // While boosting the repository keeps the base it knew, so a difference
    // only counts outside boost.
    if (!boosting && status.targetTemperature != run.target) {
      final pending = run.pendingTarget;
      if (pending == null || status.targetTemperature != pending) {
        _runs.end(run.copyWith(phase: RampRunPhase.stopped));
        return right(unit);
      }
      // A write that reported an error reached the device after all.
      return _stepped(run, pending, now);
    }

    if (now.isBefore(run.nextStepAt)) return right(unit);
    if (boosting) {
      if (!run.waitingForBoost) {
        _runs.update(run.copyWith(waitingForBoost: true));
      }
      return right(unit);
    }

    final next = _ramps.next(run.profile, run.target);
    if (next == null) {
      _runs.end(run.copyWith(phase: RampRunPhase.finished));
      return right(unit);
    }
    final written = await _portable.setTargetTemperature(next);
    if (written.isLeft()) {
      _runs.update(run.copyWith(pendingTarget: next));
      return written;
    }
    return _stepped(run, next, now);
  }

  Either<AppError, Unit> _stepped(RampRun run, int target, DateTime now) {
    final after = _ramps.next(run.profile, target);
    final late = now.difference(run.nextStepAt) > _lateAfter;
    final stepped = run.copyWith(
      target: target,
      nextTarget: after,
      clearNextTarget: after == null,
      nextStepAt: (late ? now : run.nextStepAt).add(run.profile.interval),
      waitingForBoost: false,
      clearPendingTarget: true,
    );
    if (after == null) {
      _runs.end(stepped.copyWith(phase: RampRunPhase.finished));
    } else {
      _runs.update(stepped);
    }
    return right(unit);
  }
}
