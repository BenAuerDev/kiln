import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app_view_model.dart';

import '../features/app_settings/setup_dependencies.dart';
import '../features/devices/setup_dependencies.dart';
import '../features/portable/setup_dependencies.dart';
import '../features/volcano/setup_dependencies.dart';
import 'ble/ble_client.dart';
import 'ble/demo/ble_simulator.dart';
import 'l10n/l10n_service.dart';
import 'services/app_lifecycle_service.dart';
import 'services/haptics_service.dart';
import 'services/system_locale_service.dart';
import 'services/toast_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl
    ..registerLazySingleton(SharedPreferencesAsync.new)
    ..registerLazySingleton(BleSimulator.new)
    ..registerLazySingleton(() => BleClient(sl()))
    ..registerLazySingleton(HapticsService.new)
    ..registerLazySingleton(ToastService.new)
    ..registerLazySingleton(L10nService.new)
    ..registerLazySingleton(
      AppLifecycleService.new,
      dispose: (service) => service.dispose(),
    )
    ..registerLazySingleton(
      SystemLocaleService.new,
      dispose: (service) => service.dispose(),
    );
  sl.registerFactory(AppViewModel.new);
  setupAppSettingsDependencies();
  setupDevicesDependencies();
  setupPortableDependencies();
  setupVolcanoDependencies();
}
