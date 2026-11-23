import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../volcano/domain/models/volcano_status.dart';
import '../../../volcano/domain/repositories/volcano_repository.dart';
import '../../../volcano/domain/services/volcano_target_rules.dart';
import '../models/workflow_run.dart';
import '../models/workflow_step.dart';
import '../repositories/workflow_run_repository.dart';
import '../services/workflow_step_service.dart';

/// One tick of the running workflow: sends the current step's writes (once,
/// retried until they go through), updates the progress and moves on when
/// the step is done. [skip] moves on right away.
///
/// The run pauses while its Volcano is not connected and stops, without
/// writing anything, when another device becomes active or the pause lasts
/// longer than [maxPause].
///
/// Callers run it through `WorkflowRunRepository.serialized`.
class AdvanceWorkflowRunUseCase {
  AdvanceWorkflowRunUseCase({
    WorkflowRunRepository? runs,
    VolcanoRepository? volcano,
    ConnectionRepository? connection,
    WorkflowStepService? steps,
    DateTime Function()? clock,
  }) : _runs = runs ?? sl<WorkflowRunRepository>(),
       _volcano = volcano ?? sl<VolcanoRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _steps = steps ?? sl<WorkflowStepService>(),
       _clock = clock ?? DateTime.now;

  /// A pause longer than this ends the run: kiln does not pick up a workflow
  /// when the Volcano comes back much later.
  static const maxPause = Duration(minutes: 2);

  final WorkflowRunRepository _runs;
  final VolcanoRepository _volcano;
  final ConnectionRepository _connection;
  final WorkflowStepService _steps;
  final DateTime Function() _clock;

  Future<Either<AppError, Unit>> call({bool skip = false}) async {
    var run = _runs.run.value;
    if (run == null || !run.isActive) return right(unit);
    final now = _clock();

    if (_connection.activeDeviceId.value != run.deviceId) {
      _runs.end(run.copyWith(phase: WorkflowRunPhase.interrupted));
      return skip ? left(const AppError.notConnected()) : right(unit);
    }

    final status = _volcano.status.value;
    if (status == null) {
      if (run.phase == WorkflowRunPhase.running) {
        // The writes are sent again on resume: a reconnected Volcano may
        // have lost the pump state.
        _runs.update(
          run.copyWith(
            phase: WorkflowRunPhase.paused,
            pausedAt: now,
            stepEntered: false,
          ),
        );
      } else if (now.difference(run.pausedAt ?? now) > maxPause) {
        _runs.end(run.copyWith(phase: WorkflowRunPhase.interrupted));
      }
      return skip ? left(const AppError.notConnected()) : right(unit);
    }

    if (run.phase == WorkflowRunPhase.paused) {
      run = run.copyWith(phase: WorkflowRunPhase.running, clearPausedAt: true);
    }

    if (skip) return _next(run, status, now, reached: false);

    final progress = _steps.progress(
      run.copyWith(stepEntered: true),
      currentTemperature: status.currentTemperature,
      now: now,
    );
    // A timed step that ran out while the Volcano was out of reach is not
    // started again. A heat step is always entered: the Volcano may be at
    // the target with the heater off.
    if (!run.stepEntered && (progress < 1 || run.currentStep is HeatStep)) {
      final entered = await _enter(run.currentStep, status);
      if (entered.isLeft()) {
        _runs.update(run);
        return entered;
      }
      run = run.copyWith(stepEntered: true);
    }
    run = run.copyWith(progress: progress, elapsed: _steps.elapsed(run, now));
    if (progress < 1) {
      _runs.update(run);
      return right(unit);
    }
    return _next(run, status, now, reached: true);
  }

  Future<Either<AppError, Unit>> _enter(
    WorkflowStep? step,
    VolcanoStatus status,
  ) async {
    switch (step) {
      case HeatStep(:final celsius):
        final target = VolcanoTargetRules.clamp(celsius);
        if (status.pumpOn) {
          final pump = await _volcano.setPump(false);
          if (pump.isLeft()) return pump;
        }
        if (status.targetTemperature != target) {
          final written = await _volcano.setTargetTemperature(target);
          if (written.isLeft()) return written;
        }
        if (!status.heaterOn) return _volcano.setHeater(true);
        return right(unit);
      case AirStep():
        return status.pumpOn ? right(unit) : _volcano.setPump(true);
      case HoldStep() || null:
        return right(unit);
    }
  }

  /// Leaves the current step (an air step turns the pump off) and moves to
  /// the next one, or finishes. On a failed write the run stays where it is
  /// and the next tick tries again. [reached]: the step ended because it was
  /// done, not skipped.
  Future<Either<AppError, Unit>> _next(
    WorkflowRun run,
    VolcanoStatus status,
    DateTime now, {
    required bool reached,
  }) async {
    if (run.currentStep is AirStep) {
      final off = await _volcano.setPump(false);
      if (off.isLeft()) {
        _runs.update(run);
        return off;
      }
    }
    final heatReached = reached && run.currentStep is HeatStep;
    final counted = run.copyWith(
      heatStepsReached: run.heatStepsReached + (heatReached ? 1 : 0),
    );
    final next = run.stepIndex + 1;
    if (next < run.workflow.steps.length) {
      _runs.update(
        counted.copyWith(
          stepIndex: next,
          stepStartedAt: now,
          stepEntered: false,
          stepStartTemperature: status.currentTemperature,
          progress: 0,
          elapsed: Duration.zero,
        ),
      );
      return right(unit);
    }
    if (run.workflow.heaterOffAtEnd) {
      final off = await _volcano.setHeater(false);
      if (off.isLeft()) {
        _runs.update(run);
        return off;
      }
    }
    _runs.end(counted.copyWith(phase: WorkflowRunPhase.finished, progress: 1));
    return right(unit);
  }
}
