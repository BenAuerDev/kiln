import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/app_settings_repository.dart';

class CompleteWelcomeUseCase {
  CompleteWelcomeUseCase({AppSettingsRepository? repository})
    : _repository = repository ?? sl<AppSettingsRepository>();

  final AppSettingsRepository _repository;

  Future<Either<AppError, Unit>> call() => _repository.completeWelcome();
}
