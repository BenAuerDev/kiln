import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../volcano/domain/repositories/volcano_repository.dart';
import '../models/workflow_run.dart';
import '../repositories/workflow_run_repository.dart';

/// Stops the running workflow and turns the pump and the heater off, so a
/// stopped workflow never leaves the Volcano heating. The run ends even if
/// the Volcano cannot be reached; the error is passed on so the user knows
/// it may still be on.
class StopWorkflowRunUseCase {
  StopWorkflowRunUseCase({
    WorkflowRunRepository? runs,
    VolcanoRepository? volcano,
  }) : _runs = runs ?? sl<WorkflowRunRepository>(),
       _volcano = volcano ?? sl<VolcanoRepository>();

  final WorkflowRunRepository _runs;
  final VolcanoRepository _volcano;

  /// Waits for a tick that is under way, so its writes cannot land after
  /// the "off" writes. With [deviceId], only a run on that device is
  /// stopped (kiln is about to let go of it).
  Future<Either<AppError, Unit>> call({String? deviceId}) =>
      _runs.serialized(() async {
        final run = _runs.run.value;
        if (run == null || !run.isActive) return right(unit);
        if (deviceId != null && run.deviceId != deviceId) return right(unit);
        _runs.end(run.copyWith(phase: WorkflowRunPhase.stopped));
        if (_volcano.status.value == null) {
          return left(const AppError.notConnected());
        }
        final pump = await _volcano.setPump(false);
        final heater = await _volcano.setHeater(false);
        return pump.flatMap((_) => heater);
      });
}
