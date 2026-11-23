import '../../core/service_locator.dart';
import 'data/data_sources/app_settings_data_source.dart';
import 'domain/repositories/app_settings_repository.dart';
import 'domain/use_cases/complete_welcome_use_case.dart';
import 'domain/use_cases/set_app_locale_use_case.dart';

void setupAppSettingsDependencies() {
  sl
    ..registerLazySingleton(() => AppSettingsDataSource(sl()))
    ..registerLazySingleton(AppSettingsRepository.new)
    ..registerFactory(SetAppLocaleUseCase.new)
    ..registerFactory(CompleteWelcomeUseCase.new);
}
