import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/ramps_repository.dart';

class DeleteRampUseCase {
  DeleteRampUseCase({RampsRepository? repository})
    : _repository = repository ?? sl<RampsRepository>();

  final RampsRepository _repository;

  Future<Either<AppError, Unit>> call(String id) => _repository.delete(id);
}
