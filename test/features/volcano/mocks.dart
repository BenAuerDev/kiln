import 'package:kiln/core/ble/ble_client.dart';
import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/haptics_service.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/devices/domain/repositories/known_devices_repository.dart';
import 'package:kiln/features/volcano/data/data_sources/volcano_ble_data_source.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/domain/repositories/volcano_repository.dart';
import 'package:kiln/features/volcano/domain/use_cases/adjust_volcano_target_use_case.dart';
import 'package:kiln/features/volcano/domain/use_cases/set_volcano_target_use_case.dart';
import 'package:kiln/features/volcano/domain/use_cases/start_volcano_session_use_case.dart';
import 'package:kiln/features/volcano/domain/use_cases/stop_volcano_session_use_case.dart';
import 'package:kiln/features/volcano/domain/use_cases/toggle_volcano_heater_use_case.dart';
import 'package:kiln/features/volcano/domain/use_cases/toggle_volcano_pump_use_case.dart';
import 'package:kiln/features/volcano/presentation/navigation/volcano_navigator.dart';
import 'package:mocktail/mocktail.dart';

class MockBleClient extends Mock implements BleClient {}

class MockVolcanoBleDataSource extends Mock implements VolcanoBleDataSource {}

class MockVolcanoRepository extends Mock implements VolcanoRepository {}

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockKnownDevicesRepository extends Mock
    implements KnownDevicesRepository {}

class MockStartVolcanoSessionUseCase extends Mock
    implements StartVolcanoSessionUseCase {}

class MockStopVolcanoSessionUseCase extends Mock
    implements StopVolcanoSessionUseCase {}

class MockSetVolcanoTargetUseCase extends Mock
    implements SetVolcanoTargetUseCase {}

class MockAdjustVolcanoTargetUseCase extends Mock
    implements AdjustVolcanoTargetUseCase {}

class MockToggleVolcanoHeaterUseCase extends Mock
    implements ToggleVolcanoHeaterUseCase {}

class MockToggleVolcanoPumpUseCase extends Mock
    implements ToggleVolcanoPumpUseCase {}

class MockHapticsService extends Mock implements HapticsService {}

class MockToastService extends Mock implements ToastService {}

class MockL10nService extends Mock implements L10nService {}

class MockVolcanoNavigator extends Mock implements VolcanoNavigator {}

const sampleStatus = VolcanoStatus(
  currentTemperature: 96.5,
  targetTemperature: 185,
  heaterOn: true,
  pumpOn: false,
  autoShutdown: true,
  fahrenheit: false,
  displayOnCooling: true,
  vibrationWhenReady: true,
);
