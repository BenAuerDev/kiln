import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/app_lifecycle_service.dart';
import 'package:kiln/features/background/data/data_sources/background_service_data_source.dart';
import 'package:kiln/features/background/domain/repositories/background_service_repository.dart';
import 'package:kiln/features/background/domain/use_cases/alert_ready_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/current_heat_session_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/device_session_target_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/start_device_session_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/dismiss_ready_alert_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/reset_background_service_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/show_background_session_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/set_portable_polling_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockBackgroundServiceDataSource extends Mock
    implements BackgroundServiceDataSource {}

class MockBackgroundServiceRepository extends Mock
    implements BackgroundServiceRepository {}

class MockCurrentHeatSessionUseCase extends Mock
    implements CurrentHeatSessionUseCase {}

class MockShowBackgroundSessionUseCase extends Mock
    implements ShowBackgroundSessionUseCase {}

class MockAlertReadyUseCase extends Mock implements AlertReadyUseCase {}

class MockDismissReadyAlertUseCase extends Mock
    implements DismissReadyAlertUseCase {}

class MockResetBackgroundServiceUseCase extends Mock
    implements ResetBackgroundServiceUseCase {}

class MockDeviceSessionTargetUseCase extends Mock
    implements DeviceSessionTargetUseCase {}

class MockStartDeviceSessionUseCase extends Mock
    implements StartDeviceSessionUseCase {}

class MockSetPortablePollingUseCase extends Mock
    implements SetPortablePollingUseCase {}

class MockAppLifecycleService extends Mock implements AppLifecycleService {}

class FakeL10nService extends L10nService {}
