import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../volcano/domain/repositories/volcano_repository.dart';
import '../models/workflow.dart';
import '../models/workflow_run.dart';
import '../models/workflow_step.dart';
import '../repositories/workflow_run_repository.dart';
import 'advance_workflow_run_use_case.dart';

/// Starts [workflow] on the connected Volcano and sends the first step right
/// away. A run that is still going is replaced; if it was pumping, the pump
/// goes off first. Composes [AdvanceWorkflowRunUseCase], which then runs on
/// every tick.
class StartWorkflowRunUseCase {
  StartWorkflowRunUseCase({
    WorkflowRunRepository? runs,
    VolcanoRepository? volcano,
    ConnectionRepository? connection,
    AdvanceWorkflowRunUseCase? advance,
    DateTime Function()? clock,
  }) : _runs = runs ?? sl<WorkflowRunRepository>(),
       _volcano = volcano ?? sl<VolcanoRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _advance = advance ?? sl<AdvanceWorkflowRunUseCase>(),
       _clock = clock ?? DateTime.now;

  final WorkflowRunRepository _runs;
  final VolcanoRepository _volcano;
  final ConnectionRepository _connection;
  final AdvanceWorkflowRunUseCase _advance;
  final DateTime Function() _clock;

  Future<Either<AppError, Unit>> call(Workflow workflow) =>
      _runs.serialized(() async {
        if (workflow.steps.isEmpty) return right(unit);
        final status = _volcano.status.value;
        final deviceId = _connection.activeDeviceId.value;
        if (status == null || deviceId == null) {
          return left(const AppError.notConnected());
        }
        final previous = _runs.run.value;
        if (previous != null &&
            previous.isActive &&
            previous.currentStep is AirStep) {
          final off = await _volcano.setPump(false);
          if (off.isLeft()) return off;
        }
        _runs.start(
          WorkflowRun(
            workflow: workflow,
            deviceId: deviceId,
            stepIndex: 0,
            stepStartedAt: _clock(),
            stepStartTemperature: status.currentTemperature,
          ),
          () async => _advance(),
        );
        return _advance();
      });
}
