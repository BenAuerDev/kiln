import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/volcano/domain/models/volcano_heat_phase.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_control_view_model.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_tab.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const id = 'AA:BB';
  const device = KnownDevice(
    id: id,
    name: 'S&B VOLCANO H',
    model: DeviceModel.volcanoHybrid,
  );

  late MockVolcanoRepository repository;
  late MockConnectionRepository connection;
  late MockKnownDevicesRepository knownDevices;
  late MockStartVolcanoSessionUseCase startSession;
  late MockStopVolcanoSessionUseCase stopSession;
  late MockSetVolcanoTargetUseCase setTarget;
  late MockAdjustVolcanoTargetUseCase adjustTarget;
  late MockToggleVolcanoHeaterUseCase toggleHeater;
  late MockToggleVolcanoPumpUseCase togglePump;
  late MockHapticsService haptics;
  late MockToastService toasts;
  late MockL10nService l10n;
  late MockVolcanoNavigator navigator;
  late Signal<VolcanoStatus?> status;
  late Signal<bool> sessionActive;
  late Signal<String?> activeDeviceId;
  late Signal<ConnectionStatus> connectionStatus;
  late VolcanoControlViewModel vm;
  final strings = lookupAppLocalizations(const Locale('en'));

  VolcanoControlViewModel build() => VolcanoControlViewModel(
    repository: repository,
    connection: connection,
    knownDevices: knownDevices,
    startSession: startSession,
    stopSession: stopSession,
    setTarget: setTarget,
    adjustTarget: adjustTarget,
    toggleHeater: toggleHeater,
    togglePump: togglePump,
    haptics: haptics,
    toasts: toasts,
    l10n: l10n,
    navigator: navigator,
    savedFeedbackDelay: const Duration(milliseconds: 10),
  );

  setUpAll(() => registerFallbackValue(ToastLevel.info));

  setUp(() {
    repository = MockVolcanoRepository();
    connection = MockConnectionRepository();
    knownDevices = MockKnownDevicesRepository();
    startSession = MockStartVolcanoSessionUseCase();
    stopSession = MockStopVolcanoSessionUseCase();
    setTarget = MockSetVolcanoTargetUseCase();
    adjustTarget = MockAdjustVolcanoTargetUseCase();
    toggleHeater = MockToggleVolcanoHeaterUseCase();
    togglePump = MockToggleVolcanoPumpUseCase();
    haptics = MockHapticsService();
    toasts = MockToastService();
    l10n = MockL10nService();
    navigator = MockVolcanoNavigator();

    status = signal<VolcanoStatus?>(null);
    sessionActive = signal(false);
    activeDeviceId = signal<String?>(null);
    connectionStatus = signal(ConnectionStatus.disconnected);

    when(() => repository.status).thenReturn(status);
    when(() => repository.sessionActive).thenReturn(sessionActive);
    when(() => connection.activeDeviceId).thenReturn(activeDeviceId);
    when(() => connection.status).thenReturn(connectionStatus);
    when(() => knownDevices.byId(id)).thenReturn(device);
    when(() => l10n.strings).thenReturn(strings);
    when(() => startSession(any())).thenAnswer((_) async {
      status.value = sampleStatus;
      sessionActive.value = true;
      return right(unit);
    });
    when(() => stopSession()).thenAnswer((_) async {
      status.value = null;
      sessionActive.value = false;
      return right(unit);
    });
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});

    vm = build();
  });

  tearDown(() => vm.dispose());

  Future<void> connect() async {
    batch(() {
      activeDeviceId.value = id;
      connectionStatus.value = ConnectionStatus.connected;
    });
    await pumpEventQueue();
  }

  group('session', () {
    test('does not start while disconnected', () async {
      await pumpEventQueue();
      verifyNever(() => startSession(any()));
    });

    test('starts for the active device once connected', () async {
      await connect();

      verify(() => startSession(id)).called(1);
      expect(vm.controlsEnabled.value, isTrue);
      expect(vm.phase.value, VolcanoHeatPhase.heating);
    });

    test('stops when the connection goes away', () async {
      await connect();

      connectionStatus.value = ConnectionStatus.reconnecting;
      await pumpEventQueue();

      verify(() => stopSession()).called(1);
      expect(vm.controlsEnabled.value, isFalse);
    });

    test('does not stop on dispose', () async {
      await connect();
      vm.dispose();
      verifyNever(() => stopSession());
      vm = build();
    });

    test('shows a toast when the start fails', () async {
      when(
        () => startSession(any()),
      ).thenAnswer((_) async => left(const AppError.timeout()));

      await connect();

      verify(
        () => toasts.show(strings.errorTimeout, level: ToastLevel.error),
      ).called(1);
    });

    test('stays quiet when a start was superseded', () async {
      when(
        () => startSession(any()),
      ).thenAnswer((_) async => left(const AppError.notConnected()));

      await connect();

      verifyNever(() => toasts.show(any(), level: any(named: 'level')));
    });
  });

  test('deviceName follows the active known device', () async {
    expect(vm.deviceName.value, isNull);
    await connect();
    expect(vm.deviceName.value, 'Volcano Hybrid');
  });

  group('target steps', () {
    setUp(connect);

    test(
      'tick per step and one success haptic after the steps settle',
      () async {
        when(() => adjustTarget(1)).thenAnswer((_) async => right(some(186)));

        vm.increaseTarget();
        vm.increaseTarget();
        await pumpEventQueue();

        verify(() => haptics.tick()).called(2);
        verifyNever(() => haptics.success());

        await Future<void>.delayed(const Duration(milliseconds: 30));

        verify(() => haptics.success()).called(1);
        verifyNever(() => toasts.show(any(), level: any(named: 'level')));
      },
    );

    test('a clamped step does nothing', () async {
      when(() => adjustTarget(-1)).thenAnswer((_) async => right(none()));

      vm.decreaseTarget();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verifyNever(() => haptics.tick());
      verifyNever(() => haptics.success());
      verifyNever(() => toasts.show(any(), level: any(named: 'level')));
    });

    test('an error shows a toast', () async {
      when(
        () => adjustTarget(1),
      ).thenAnswer((_) async => left(const AppError.connectionLost()));

      vm.increaseTarget();
      await pumpEventQueue();

      verify(() => haptics.warning()).called(1);
      verify(
        () => toasts.show(strings.errorConnectionLost, level: ToastLevel.error),
      ).called(1);
    });
  });

  group('presets and toggles', () {
    setUp(connect);

    test('a preset confirms immediately, without a toast', () async {
      when(() => setTarget(200)).thenAnswer((_) async => right(some(200)));

      await vm.selectPreset(200);

      verify(() => haptics.success()).called(1);
      verifyNever(() => toasts.show(any(), level: any(named: 'level')));
    });

    test('the current preset does not write feedback', () async {
      when(() => setTarget(185)).thenAnswer((_) async => right(none()));

      await vm.selectPreset(185);

      verifyNever(() => haptics.success());
    });

    test('heater toggle confirms', () async {
      when(() => toggleHeater()).thenAnswer((_) async => right(false));

      await vm.toggleHeater();

      verify(() => haptics.success()).called(1);
    });

    test('pump toggle error shows a toast', () async {
      when(
        () => togglePump(),
      ).thenAnswer((_) async => left(const AppError.writeNotVerified('x')));

      await vm.togglePump();

      verify(
        () =>
            toasts.show(strings.errorWriteNotVerified, level: ToastLevel.error),
      ).called(1);
    });
  });

  test('the Devices tab goes to the devices screen', () {
    vm
      ..selectTab(VolcanoTab.control)
      ..selectTab(VolcanoTab.devices);

    verify(() => navigator.goToDevices()).called(1);
  });
}
