import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../portable/domain/extensions/portable_status_x.dart';
import '../../../portable/domain/models/heater_mode.dart';
import '../../../portable/domain/repositories/portable_repository.dart';
import '../models/ramp_profile.dart';
import '../models/ramp_run.dart';
import '../repositories/ramp_run_repository.dart';
import '../services/ramp_service.dart';
import 'advance_ramp_use_case.dart';

/// Starts [RampProfile] on the connected Venty/Veazy: sets the base to the
/// first temperature (clamped to 40–210 °C) and turns the heater on if it is
/// off. Not while boosting, when target writes are blocked. Composes
/// [AdvanceRampUseCase], which then runs on every tick.
class StartRampUseCase {
  StartRampUseCase({
    RampRunRepository? runs,
    PortableRepository? portable,
    ConnectionRepository? connection,
    RampService? ramps,
    AdvanceRampUseCase? advance,
    DateTime Function()? clock,
  }) : _runs = runs ?? sl<RampRunRepository>(),
       _portable = portable ?? sl<PortableRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _ramps = ramps ?? sl<RampService>(),
       _advance = advance ?? sl<AdvanceRampUseCase>(),
       _clock = clock ?? DateTime.now;

  final RampRunRepository _runs;
  final PortableRepository _portable;
  final ConnectionRepository _connection;
  final RampService _ramps;
  final AdvanceRampUseCase _advance;
  final DateTime Function() _clock;

  Future<Either<AppError, Unit>> call(RampProfile profile) =>
      _runs.serialized(() async {
        final status = _portable.status.value;
        final deviceId = _connection.activeDeviceId.value;
        if (status == null || deviceId == null) {
          return left(const AppError.notConnected());
        }
        if (status.boostActive) {
          return left(const AppError.writeNotVerified('targetTemperature'));
        }
        final first = _ramps.targets(profile).first;
        if (status.targetTemperature != first) {
          final written = await _portable.setTargetTemperature(first);
          if (written.isLeft()) return written;
        }
        if (status.heaterMode == HeaterMode.off) {
          final on = await _portable.setHeaterMode(HeaterMode.normal);
          if (on.isLeft()) return on;
        }
        _runs.start(
          RampRun(
            profile: profile,
            deviceId: deviceId,
            session: _portable.sessionNumber.value,
            target: first,
            nextTarget: _ramps.next(profile, first),
            nextStepAt: _clock().add(profile.interval),
          ),
          () async => _advance(),
        );
        return right(unit);
      });
}
