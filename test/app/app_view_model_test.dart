import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/app/app_view_model.dart';
import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/app_lifecycle_service.dart';
import 'package:kiln/core/services/haptics_service.dart';
import 'package:kiln/core/services/system_locale_service.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/finish_preference.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/devices/domain/repositories/known_devices_repository.dart';
import 'package:kiln/features/devices/domain/use_cases/reconnect_last_device_use_case.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_settings.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/repositories/portable_repository.dart';
import 'package:kiln/features/portable/domain/use_cases/set_portable_polling_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/sync_portable_reconnect_use_case.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/services/workflow_step_service.dart';
import 'package:kiln/features/workflows/domain/use_cases/stop_workflow_run_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class MockKnownDevicesRepository extends Mock
    implements KnownDevicesRepository {}

class MockAppLifecycleService extends Mock implements AppLifecycleService {}

class MockL10nService extends Mock implements L10nService {}

class MockSystemLocaleService extends Mock implements SystemLocaleService {}

class MockReconnectLastDeviceUseCase extends Mock
    implements ReconnectLastDeviceUseCase {}

class MockPortableRepository extends Mock implements PortableRepository {}

class MockSyncPortableReconnectUseCase extends Mock
    implements SyncPortableReconnectUseCase {}

class MockHapticsService extends Mock implements HapticsService {}

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockStopWorkflowRunUseCase extends Mock
    implements StopWorkflowRunUseCase {}

class MockSetPortablePollingUseCase extends Mock
    implements SetPortablePollingUseCase {}

void main() {
  late Signal<String?> localeCode;
  late Signal<KnownDevice?> activeDevice;
  late Signal<AppLifecycleState> lifecycle;
  late Signal<List<Locale>> systemLocales;
  late MockL10nService l10n;
  late MockReconnectLastDeviceUseCase reconnect;
  late MockSyncPortableReconnectUseCase syncReconnect;
  late Signal<PortableStatus?> portableStatus;
  late Signal<bool> welcomeCompleted;
  late Signal<List<KnownDevice>> devices;
  late WorkflowRunRepository workflowRuns;
  late MockHapticsService haptics;
  late MockConnectionRepository connection;
  late MockStopWorkflowRunUseCase stopRun;
  late MockSetPortablePollingUseCase setPolling;
  late AppViewModel vm;

  setUpAll(() => registerFallbackValue(const [Locale('en')]));

  setUp(() {
    localeCode = signal(null);
    activeDevice = signal(null);
    lifecycle = signal(AppLifecycleState.resumed);
    systemLocales = signal(const [Locale('en')]);
    final systemLocaleService = MockSystemLocaleService();
    when(() => systemLocaleService.locales).thenReturn(systemLocales);
    final settings = MockAppSettingsRepository();
    final knownDevices = MockKnownDevicesRepository();
    final lifecycleService = MockAppLifecycleService();
    l10n = MockL10nService();
    reconnect = MockReconnectLastDeviceUseCase();
    syncReconnect = MockSyncPortableReconnectUseCase();
    portableStatus = signal(null);
    final portable = MockPortableRepository();
    when(() => portable.status).thenReturn(portableStatus);
    when(() => settings.localeCode).thenReturn(localeCode);
    welcomeCompleted = signal(false);
    devices = signal(const []);
    when(() => settings.welcomeCompleted).thenReturn(welcomeCompleted);
    when(() => knownDevices.devices).thenReturn(devices);
    when(() => knownDevices.activeDevice).thenReturn(activeDevice);
    when(() => lifecycleService.state).thenReturn(lifecycle);
    when(() => reconnect()).thenAnswer((_) async => right(none()));
    workflowRuns = WorkflowRunRepository();
    haptics = MockHapticsService();
    when(() => haptics.success()).thenAnswer((_) async {});
    connection = MockConnectionRepository();
    stopRun = MockStopWorkflowRunUseCase();
    when(
      () => stopRun(deviceId: any(named: 'deviceId')),
    ).thenAnswer((_) async => right(unit));
    setPolling = MockSetPortablePollingUseCase();
    vm = AppViewModel(
      settings: settings,
      knownDevices: knownDevices,
      lifecycle: lifecycleService,
      systemLocale: systemLocaleService,
      l10n: l10n,
      reconnectLastDevice: reconnect,
      setPortablePolling: setPolling,
      portable: portable,
      syncPortableReconnect: syncReconnect,
      connection: connection,
      stopWorkflowRun: stopRun,
      workflowRuns: workflowRuns,
      workflowSteps: WorkflowStepService(),
      haptics: haptics,
    );
  });

  tearDown(() => vm.dispose());

  test('stops a workflow before kiln lets go of its device', () async {
    final hook =
        verify(() => connection.beforeRelease = captureAny()).captured.single
            as Future<void> Function(String);
    await hook('volcano-id');
    verify(() => stopRun(deviceId: 'volcano-id')).called(1);
  });

  test('buzzes when a workflow reaches a heat step, on any screen', () {
    final run = WorkflowRun(
      deviceId: 'v',
      workflow: WorkflowPresets.all.first,
      stepIndex: 0,
      stepStartedAt: DateTime(2026),
    );
    workflowRuns.update(run);
    workflowRuns.update(run.copyWith(stepIndex: 1));
    verifyNever(() => haptics.success());
    workflowRuns.update(run.copyWith(stepIndex: 1, heatStepsReached: 1));
    verify(() => haptics.success()).called(1);
  });

  group('pastWelcome', () {
    test('is false before the welcome is completed', () {
      expect(vm.pastWelcome.value, isFalse);
    });

    test('is true once the welcome is completed', () {
      welcomeCompleted.value = true;
      expect(vm.pastWelcome.value, isTrue);
    });

    test('is true while a demo runs, and false again after it', () {
      devices.value = const [
        KnownDevice(
          id: 'demo:veazy',
          name: 'kiln demo',
          model: DeviceModel.veazy,
        ),
      ];
      expect(vm.pastWelcome.value, isTrue);
      devices.value = const [];
      expect(vm.pastWelcome.value, isFalse);
    });

    test('stays true for a device paired during a demo', () {
      devices.value = const [
        KnownDevice(id: 'real', name: 'S&B VZ1', model: DeviceModel.veazy),
      ];
      expect(vm.pastWelcome.value, isTrue);
    });
  });

  group('finish', () {
    test('is ember without an active device', () {
      expect(vm.finish.value, KilnPalette.ember);
    });

    test('follows the fixed finish of the active device', () {
      activeDevice.value = const KnownDevice(
        id: 'a',
        name: 'S&B VZ1',
        model: DeviceModel.veazy,
        finishPreference: FixedFinish(DeviceFinish.pink),
      );

      expect(vm.finish.value, KilnPalette.pink);
    });

    test('matches the detected finish of the active device', () {
      activeDevice.value = const KnownDevice(
        id: 'a',
        name: 'S&B VZ1',
        model: DeviceModel.veazy,
        detectedFinish: DeviceFinish.blue,
      );

      expect(vm.finish.value, KilnPalette.blue);
    });
  });

  group('reconnect', () {
    test('reconnects on start', () {
      verify(() => reconnect()).called(1);
    });

    test('reconnects again when the app is resumed', () {
      lifecycle.value = AppLifecycleState.paused;
      lifecycle.value = AppLifecycleState.resumed;

      verify(() => reconnect()).called(2);
    });

    test('does not reconnect while paused', () {
      clearInteractions(reconnect);
      lifecycle.value = AppLifecycleState.paused;

      verifyNever(() => reconnect());
    });
  });

  group('portable polling', () {
    test('pauses when the app goes to the background', () {
      lifecycle.value = AppLifecycleState.hidden;

      verify(() => setPolling(active: false)).called(1);
    });

    test('resumes when the app is visible again', () {
      clearInteractions(setPolling);
      lifecycle.value = AppLifecycleState.paused;
      lifecycle.value = AppLifecycleState.resumed;

      verify(() => setPolling(active: false)).called(1);
      verify(() => setPolling(active: true)).called(1);
    });

    test('keeps polling while only inactive', () {
      clearInteractions(setPolling);
      lifecycle.value = AppLifecycleState.inactive;

      verifyNever(() => setPolling(active: any(named: 'active')));
    });
  });

  group('portable reconnect policy', () {
    PortableStatus status(HeaterMode mode) => PortableStatus(
      currentTemperature: null,
      targetTemperature: 185,
      boostOffset: 15,
      superBoostOffset: 10,
      batteryPercent: 70,
      charging: false,
      heaterMode: mode,
      autoOffSeconds: 0,
      settings: const PortableSettings(
        fahrenheit: false,
        vibrateWhenReady: true,
        ecoCharge: false,
        ecoVoltage: false,
        boostVisualisation: true,
      ),
    );

    test('follows every new status', () {
      final off = status(HeaterMode.off);
      portableStatus.value = off;

      verify(() => syncReconnect(off)).called(1);
    });

    test('keeps the last decision when the session ends', () {
      portableStatus.value = status(HeaterMode.normal);
      clearInteractions(syncReconnect);

      portableStatus.value = null;

      verifyNoMoreInteractions(syncReconnect);
    });
  });

  group('locale', () {
    test('follows the system language without an override', () {
      systemLocales.value = const [Locale('fr'), Locale('de')];

      verify(
        () => l10n.updateLocales(const [Locale('fr'), Locale('de')]),
      ).called(1);
    });

    test('a stored language wins over the system language', () {
      localeCode.value = 'en';
      clearInteractions(l10n);

      systemLocales.value = const [Locale('de')];

      verifyNever(() => l10n.updateLocales(any()));
    });

    test('applies a stored language to the l10n service', () {
      localeCode.value = 'de';

      expect(vm.locale.value, const Locale('de'));
      verify(() => l10n.updateLocales(const [Locale('de')])).called(1);
    });
  });
}
