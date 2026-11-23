import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/workflow_run_repository.dart';
import 'advance_workflow_run_use_case.dart';

/// Ends the current step now (an air step turns the pump off) and moves on.
class SkipWorkflowStepUseCase {
  SkipWorkflowStepUseCase({
    WorkflowRunRepository? runs,
    AdvanceWorkflowRunUseCase? advance,
  }) : _runs = runs ?? sl<WorkflowRunRepository>(),
       _advance = advance ?? sl<AdvanceWorkflowRunUseCase>();

  final WorkflowRunRepository _runs;
  final AdvanceWorkflowRunUseCase _advance;

  Future<Either<AppError, Unit>> call() =>
      _runs.serialized(() => _advance(skip: true));
}
