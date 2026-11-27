import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/ramps_repository.dart';

class LoadRampsUseCase {
  LoadRampsUseCase({RampsRepository? repository})
    : _repository = repository ?? sl<RampsRepository>();

  final RampsRepository _repository;

  Future<Either<AppError, Unit>> call() => _repository.load();
}
