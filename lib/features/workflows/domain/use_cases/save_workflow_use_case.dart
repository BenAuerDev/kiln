import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/workflow.dart';
import '../repositories/workflows_repository.dart';
import '../services/workflow_editing_service.dart';

/// Saves a user workflow: trims the name, brings every step into the limits
/// and gives a new workflow (empty id) its id. Returns the saved workflow, or
/// `none()` when it has no name or no steps (nothing is saved).
class SaveWorkflowUseCase {
  SaveWorkflowUseCase({
    WorkflowsRepository? repository,
    WorkflowEditingService? editing,
    DateTime Function()? clock,
  }) : _repository = repository ?? sl<WorkflowsRepository>(),
       _editing = editing ?? sl<WorkflowEditingService>(),
       _clock = clock ?? DateTime.now;

  final WorkflowsRepository _repository;
  final WorkflowEditingService _editing;
  final DateTime Function() _clock;

  Future<Either<AppError, Option<Workflow>>> call(Workflow draft) async {
    final trimmed = draft.name.trim();
    final name = trimmed.length > WorkflowEditingService.maxNameLength
        ? trimmed.substring(0, WorkflowEditingService.maxNameLength)
        : trimmed;
    final steps = draft.steps
        .take(WorkflowEditingService.maxSteps)
        .map(_editing.normalise)
        .toList(growable: false);
    if (!_editing.canSave(name, steps)) return right(none());
    final workflow = Workflow(
      id: draft.id.isEmpty || draft.isPreset
          ? 'user.${_clock().microsecondsSinceEpoch}'
          : draft.id,
      name: name,
      steps: steps,
      heaterOffAtEnd: draft.heaterOffAtEnd,
    );
    return (await _repository.save(workflow)).map((_) => some(workflow));
  }
}
