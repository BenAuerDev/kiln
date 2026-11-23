import '../../core/service_locator.dart';
import 'data/data_sources/device_connection_data_source.dart';
import 'data/data_sources/device_scan_data_source.dart';
import 'data/data_sources/known_devices_data_source.dart';
import 'domain/repositories/connection_repository.dart';
import 'domain/repositories/known_devices_repository.dart';
import 'domain/repositories/scan_repository.dart';
import 'domain/services/device_list_service.dart';
import 'domain/services/finish_detection_service.dart';
import 'domain/services/scan_filter_service.dart';
import 'domain/use_cases/connect_device_use_case.dart';
import 'domain/use_cases/disconnect_device_use_case.dart';
import 'domain/use_cases/forget_device_use_case.dart';
import 'domain/use_cases/leave_demo_use_case.dart';
import 'domain/use_cases/load_known_devices_use_case.dart';
import 'domain/use_cases/reconnect_last_device_use_case.dart';
import 'domain/use_cases/set_detected_finish_use_case.dart';
import 'domain/use_cases/set_device_finish_use_case.dart';
import 'domain/use_cases/start_demo_use_case.dart';
import 'domain/use_cases/start_device_scan_use_case.dart';
import 'domain/use_cases/stop_device_scan_use_case.dart';
import 'presentation/navigation/devices_navigator.dart';
import 'presentation/view_models/demo_badge_view_model.dart';
import 'presentation/view_models/demo_view_model.dart';
import 'presentation/view_models/devices_view_model.dart';
import 'presentation/view_models/welcome_view_model.dart';

void setupDevicesDependencies() {
  sl
    ..registerLazySingleton(() => KnownDevicesDataSource(sl()))
    ..registerLazySingleton(() => DeviceScanDataSource(sl()))
    ..registerLazySingleton(() => DeviceConnectionDataSource(sl()))
    ..registerLazySingleton(ScanFilterService.new)
    ..registerLazySingleton(DeviceListService.new)
    ..registerLazySingleton(FinishDetectionService.new)
    ..registerLazySingleton(KnownDevicesRepository.new)
    ..registerLazySingleton(ScanRepository.new)
    ..registerLazySingleton(ConnectionRepository.new)
    ..registerLazySingleton(DevicesNavigator.new)
    ..registerFactory(StartDeviceScanUseCase.new)
    ..registerFactory(StopDeviceScanUseCase.new)
    ..registerFactory(ConnectDeviceUseCase.new)
    ..registerFactory(DisconnectDeviceUseCase.new)
    ..registerFactory(ForgetDeviceUseCase.new)
    ..registerFactory(SetDeviceFinishUseCase.new)
    ..registerFactory(SetDetectedFinishUseCase.new)
    ..registerFactory(ReconnectLastDeviceUseCase.new)
    ..registerFactory(LoadKnownDevicesUseCase.new)
    ..registerFactory(StartDemoUseCase.new)
    ..registerFactory(LeaveDemoUseCase.new)
    ..registerFactory(DemoViewModel.new)
    ..registerFactory(DemoBadgeViewModel.new)
    ..registerFactory(WelcomeViewModel.new)
    ..registerFactory(DevicesViewModel.new);
}
