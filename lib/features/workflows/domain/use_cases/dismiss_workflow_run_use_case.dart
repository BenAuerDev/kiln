import '../../../../core/service_locator.dart';
import '../repositories/workflow_run_repository.dart';

/// Forgets a finished or stopped run. A running one is left alone.
class DismissWorkflowRunUseCase {
  DismissWorkflowRunUseCase({WorkflowRunRepository? runs})
    : _runs = runs ?? sl<WorkflowRunRepository>();

  final WorkflowRunRepository _runs;

  void call() {
    final run = _runs.run.value;
    if (run != null && !run.isActive) _runs.clear();
  }
}
