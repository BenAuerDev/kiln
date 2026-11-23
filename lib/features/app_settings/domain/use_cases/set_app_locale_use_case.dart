import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/app_settings_repository.dart';

class SetAppLocaleUseCase {
  SetAppLocaleUseCase({AppSettingsRepository? repository})
    : _repository = repository ?? sl<AppSettingsRepository>();

  final AppSettingsRepository _repository;

  static const supportedCodes = {'en', 'de'};

  /// Pass `null` to follow the system language.
  Future<Either<AppError, Unit>> call(String? languageCode) {
    if (languageCode != null && !supportedCodes.contains(languageCode)) {
      return Future.value(left(AppError.protocol('locale $languageCode')));
    }
    return _repository.setLocaleCode(languageCode);
  }
}
