import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/haptics_service.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:kiln/features/app_settings/domain/use_cases/complete_welcome_use_case.dart';
import 'package:kiln/features/app_settings/domain/use_cases/set_app_locale_use_case.dart';
import 'package:kiln/features/devices/data/data_sources/device_connection_data_source.dart';
import 'package:kiln/features/devices/data/data_sources/device_scan_data_source.dart';
import 'package:kiln/features/devices/data/data_sources/known_devices_data_source.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/devices/domain/repositories/known_devices_repository.dart';
import 'package:kiln/features/devices/domain/repositories/scan_repository.dart';
import 'package:kiln/features/devices/domain/use_cases/connect_device_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/disconnect_device_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/forget_device_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/leave_demo_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/start_demo_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/start_device_scan_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/stop_device_scan_use_case.dart';
import 'package:kiln/features/devices/presentation/navigation/devices_navigator.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceConnectionDataSource extends Mock
    implements DeviceConnectionDataSource {}

class MockDeviceScanDataSource extends Mock implements DeviceScanDataSource {}

class MockKnownDevicesDataSource extends Mock
    implements KnownDevicesDataSource {}

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockKnownDevicesRepository extends Mock
    implements KnownDevicesRepository {}

class MockScanRepository extends Mock implements ScanRepository {}

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class MockStartDeviceScanUseCase extends Mock
    implements StartDeviceScanUseCase {}

class MockStopDeviceScanUseCase extends Mock implements StopDeviceScanUseCase {}

class MockConnectDeviceUseCase extends Mock implements ConnectDeviceUseCase {}

class MockDisconnectDeviceUseCase extends Mock
    implements DisconnectDeviceUseCase {}

class MockForgetDeviceUseCase extends Mock implements ForgetDeviceUseCase {}

class MockCompleteWelcomeUseCase extends Mock
    implements CompleteWelcomeUseCase {}

class MockSetAppLocaleUseCase extends Mock implements SetAppLocaleUseCase {}

class MockHapticsService extends Mock implements HapticsService {}

class MockToastService extends Mock implements ToastService {}

class MockDevicesNavigator extends Mock implements DevicesNavigator {}

class FakeL10nService extends L10nService {}

class MockStartDemoUseCase extends Mock implements StartDemoUseCase {}

class MockLeaveDemoUseCase extends Mock implements LeaveDemoUseCase {}
