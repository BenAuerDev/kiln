import 'dart:ui';

import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/haptics_service.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/devices/domain/repositories/known_devices_repository.dart';
import 'package:kiln/features/devices/domain/use_cases/forget_device_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/set_device_finish_use_case.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/adjust_base_temperature_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/adjust_boost_offset_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/adjust_super_boost_offset_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/apply_quick_setup_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/find_portable_device_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/set_base_temperature_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/start_portable_session_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/stop_portable_session_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/toggle_portable_boost_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/toggle_portable_heater_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/update_portable_settings_use_case.dart';
import 'package:kiln/features/portable/presentation/navigation/portable_navigator.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_session_binding.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../helpers/portable_fixtures.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockKnownDevicesRepository extends Mock
    implements KnownDevicesRepository {}

class MockStartPortableSessionUseCase extends Mock
    implements StartPortableSessionUseCase {}

class MockStopPortableSessionUseCase extends Mock
    implements StopPortableSessionUseCase {}

class MockAdjustBaseTemperatureUseCase extends Mock
    implements AdjustBaseTemperatureUseCase {}

class MockAdjustBoostOffsetUseCase extends Mock
    implements AdjustBoostOffsetUseCase {}

class MockAdjustSuperBoostOffsetUseCase extends Mock
    implements AdjustSuperBoostOffsetUseCase {}

class MockApplyQuickSetupUseCase extends Mock
    implements ApplyQuickSetupUseCase {}

class MockSetBaseTemperatureUseCase extends Mock
    implements SetBaseTemperatureUseCase {}

class MockTogglePortableHeaterUseCase extends Mock
    implements TogglePortableHeaterUseCase {}

class MockTogglePortableBoostUseCase extends Mock
    implements TogglePortableBoostUseCase {}

class MockFindPortableDeviceUseCase extends Mock
    implements FindPortableDeviceUseCase {}

class MockUpdatePortableSettingsUseCase extends Mock
    implements UpdatePortableSettingsUseCase {}

class MockSetDeviceFinishUseCase extends Mock
    implements SetDeviceFinishUseCase {}

class MockForgetDeviceUseCase extends Mock implements ForgetDeviceUseCase {}

class MockPortableNavigator extends Mock implements PortableNavigator {}

class MockHapticsService extends Mock implements HapticsService {}

class MockToastService extends Mock implements ToastService {}

class MockL10nService extends Mock implements L10nService {}

const deviceId = 'AA:BB';

const veazy = KnownDevice(
  id: deviceId,
  name: 'S&B VZ123456',
  model: DeviceModel.veazy,
);

final strings = lookupAppLocalizations(const Locale('en'));

/// Everything a [PortableSessionBinding] reads, as mocks backed by signals
/// the tests can drive.
class BindingHarness {
  BindingHarness({KnownDevice? device = veazy}) {
    when(() => repository.status).thenReturn(status);
    when(() => repository.sessionActive).thenReturn(sessionActive);
    when(() => connection.activeDeviceId).thenReturn(activeDeviceId);
    when(() => connection.status).thenReturn(connectionStatus);
    when(() => knownDevices.byId(any())).thenReturn(device);
    when(() => l10n.strings).thenReturn(strings);
    when(() => startSession(any(), any())).thenAnswer((_) async {
      status.value = testStatus();
      sessionActive.value = true;
      return right(unit);
    });
    when(() => stopSession()).thenAnswer((_) async {
      status.value = null;
      sessionActive.value = false;
    });
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
  }

  final repository = MockPortableRepository();
  final connection = MockConnectionRepository();
  final knownDevices = MockKnownDevicesRepository();
  final startSession = MockStartPortableSessionUseCase();
  final stopSession = MockStopPortableSessionUseCase();
  final haptics = MockHapticsService();
  final toasts = MockToastService();
  final l10n = MockL10nService();

  final status = signal<PortableStatus?>(null);
  final sessionActive = signal(false);
  final activeDeviceId = signal<String?>(null);
  final connectionStatus = signal(ConnectionStatus.disconnected);

  PortableSessionBinding binding({
    Duration savedFeedbackDelay = const Duration(milliseconds: 10),
  }) => PortableSessionBinding(
    repository: repository,
    connection: connection,
    knownDevices: knownDevices,
    startSession: startSession,
    stopSession: stopSession,
    haptics: haptics,
    toasts: toasts,
    l10n: l10n,
    savedFeedbackDelay: savedFeedbackDelay,
  );

  Future<void> connect() async {
    batch(() {
      activeDeviceId.value = deviceId;
      connectionStatus.value = ConnectionStatus.connected;
    });
    await Future<void>.delayed(Duration.zero);
  }

  void verifySaved(int times) {
    verify(() => haptics.success()).called(times);
    verify(
      () => toasts.show(
        strings.commonSavedTo('Veazy'),
        level: ToastLevel.success,
      ),
    ).called(times);
  }

  void verifyNoToast() =>
      verifyNever(() => toasts.show(any(), level: any(named: 'level')));
}
