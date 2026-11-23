import '../../core/service_locator.dart';
import 'data/data_sources/portable_ble_data_source.dart';
import 'domain/repositories/portable_repository.dart';
import 'domain/services/portable_ladder_service.dart';
import 'domain/use_cases/adjust_base_temperature_use_case.dart';
import 'domain/use_cases/adjust_boost_offset_use_case.dart';
import 'domain/use_cases/adjust_super_boost_offset_use_case.dart';
import 'domain/use_cases/apply_quick_setup_use_case.dart';
import 'domain/use_cases/find_portable_device_use_case.dart';
import 'domain/use_cases/set_base_temperature_use_case.dart';
import 'domain/use_cases/detect_portable_finish_use_case.dart';
import 'domain/use_cases/set_portable_polling_use_case.dart';
import 'domain/use_cases/start_portable_session_use_case.dart';
import 'domain/use_cases/sync_portable_reconnect_use_case.dart';
import 'domain/use_cases/stop_portable_session_use_case.dart';
import 'domain/use_cases/toggle_portable_boost_use_case.dart';
import 'domain/use_cases/toggle_portable_heater_use_case.dart';
import 'domain/use_cases/update_portable_settings_use_case.dart';
import 'presentation/navigation/portable_navigator.dart';
import 'presentation/view_models/portable_control_view_model.dart';
import 'presentation/view_models/portable_session_binding.dart';
import 'presentation/view_models/portable_settings_view_model.dart';
import 'presentation/view_models/portable_setup_view_model.dart';

void setupPortableDependencies() {
  // Data
  sl.registerLazySingleton(() => PortableBleDataSource(sl()));

  // Domain
  sl
    ..registerLazySingleton(
      PortableRepository.new,
      dispose: (repository) => repository.stopSession(),
    )
    ..registerLazySingleton(PortableLadderService.new)
    ..registerFactory(DetectPortableFinishUseCase.new)
    ..registerFactory(SetPortablePollingUseCase.new)
    ..registerFactory(SyncPortableReconnectUseCase.new)
    ..registerFactory(StartPortableSessionUseCase.new)
    ..registerFactory(StopPortableSessionUseCase.new)
    ..registerFactory(SetBaseTemperatureUseCase.new)
    ..registerFactory(AdjustBaseTemperatureUseCase.new)
    ..registerFactory(AdjustBoostOffsetUseCase.new)
    ..registerFactory(AdjustSuperBoostOffsetUseCase.new)
    ..registerFactory(ApplyQuickSetupUseCase.new)
    ..registerFactory(TogglePortableHeaterUseCase.new)
    ..registerFactory(TogglePortableBoostUseCase.new)
    ..registerFactory(UpdatePortableSettingsUseCase.new)
    ..registerFactory(FindPortableDeviceUseCase.new);

  // Presentation
  sl
    ..registerLazySingleton(PortableNavigator.new)
    ..registerFactory(PortableSessionBinding.new)
    ..registerFactory(PortableControlViewModel.new)
    ..registerFactory(PortableSetupViewModel.new)
    ..registerFactory(PortableSettingsViewModel.new);
}
