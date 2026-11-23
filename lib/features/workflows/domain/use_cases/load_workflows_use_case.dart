import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/workflows_repository.dart';

class LoadWorkflowsUseCase {
  LoadWorkflowsUseCase({WorkflowsRepository? repository})
    : _repository = repository ?? sl<WorkflowsRepository>();

  final WorkflowsRepository _repository;

  Future<Either<AppError, Unit>> call() => _repository.load();
}
