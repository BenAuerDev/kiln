import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/background_service_repository.dart';

/// At app start: stops a background service left over from an earlier run.
class ResetBackgroundServiceUseCase {
  ResetBackgroundServiceUseCase({BackgroundServiceRepository? repository})
    : _repository = repository ?? sl<BackgroundServiceRepository>();

  final BackgroundServiceRepository _repository;

  Future<Either<AppError, Unit>> call() => _repository.reset();
}
