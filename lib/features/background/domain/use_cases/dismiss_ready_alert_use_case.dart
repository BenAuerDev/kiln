import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/background_service_repository.dart';

/// Removes a "ready" alert that is no longer news.
class DismissReadyAlertUseCase {
  DismissReadyAlertUseCase({BackgroundServiceRepository? repository})
    : _repository = repository ?? sl<BackgroundServiceRepository>();

  final BackgroundServiceRepository _repository;

  Future<Either<AppError, Unit>> call() => _repository.dismissAlert();
}
