import 'package:fpdart/fpdart.dart';

import '../../../../core/service_locator.dart';
import '../models/workflow.dart';
import '../repositories/workflows_repository.dart';
import '../services/workflow_presets.dart';

/// The current version of a user workflow or preset by id; `none()` once it
/// was deleted. Reads repository signals, so it can be used in a computed.
class FindWorkflowUseCase {
  FindWorkflowUseCase({WorkflowsRepository? repository})
    : _repository = repository ?? sl<WorkflowsRepository>();

  final WorkflowsRepository _repository;

  Option<Workflow> call(String id) => Option.fromNullable(
    _repository.byId(id) ??
        WorkflowPresets.all.where((preset) => preset.id == id).firstOrNull,
  );
}
