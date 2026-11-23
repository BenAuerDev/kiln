import '../../core/service_locator.dart';
import 'data/data_sources/background_service_data_source.dart';
import 'domain/repositories/background_service_repository.dart';
import 'domain/services/background_rules.dart';
import 'domain/services/heat_session_service.dart';
import 'domain/use_cases/alert_ready_use_case.dart';
import 'domain/use_cases/current_heat_session_use_case.dart';
import 'domain/use_cases/device_session_target_use_case.dart';
import 'domain/use_cases/dismiss_ready_alert_use_case.dart';
import 'domain/use_cases/reset_background_service_use_case.dart';
import 'domain/use_cases/start_device_session_use_case.dart';
import 'domain/use_cases/show_background_session_use_case.dart';
import 'presentation/view_models/background_view_model.dart';

void setupBackgroundDependencies() {
  sl
    ..registerLazySingleton(BackgroundServiceDataSource.new)
    ..registerLazySingleton(BackgroundServiceRepository.new)
    ..registerLazySingleton(HeatSessionService.new)
    ..registerLazySingleton(BackgroundRules.new)
    ..registerFactory(CurrentHeatSessionUseCase.new)
    ..registerFactory(ShowBackgroundSessionUseCase.new)
    ..registerFactory(AlertReadyUseCase.new)
    ..registerFactory(DeviceSessionTargetUseCase.new)
    ..registerFactory(StartDeviceSessionUseCase.new)
    ..registerFactory(DismissReadyAlertUseCase.new)
    ..registerFactory(ResetBackgroundServiceUseCase.new)
    ..registerFactory(BackgroundViewModel.new);
}
