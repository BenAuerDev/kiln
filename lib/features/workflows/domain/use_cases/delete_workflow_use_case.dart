import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/workflows_repository.dart';

class DeleteWorkflowUseCase {
  DeleteWorkflowUseCase({WorkflowsRepository? repository})
    : _repository = repository ?? sl<WorkflowsRepository>();

  final WorkflowsRepository _repository;

  Future<Either<AppError, Unit>> call(String id) => _repository.delete(id);
}
