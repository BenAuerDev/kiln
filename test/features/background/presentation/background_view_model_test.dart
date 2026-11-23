import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/background/domain/models/background_notice.dart';
import 'package:kiln/features/background/domain/models/heat_session.dart';
import 'package:kiln/features/background/domain/services/background_rules.dart';
import 'package:kiln/features/background/presentation/extensions/heat_session_x.dart';
import 'package:kiln/features/background/presentation/view_models/background_view_model.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../mocks.dart';

void main() {
  late Signal<HeatSession?> session;
  late Signal<AppLifecycleState> lifecycle;
  late MockShowBackgroundSessionUseCase show;
  late MockAlertReadyUseCase alert;
  late MockSetPortablePollingUseCase polling;
  late MockDismissReadyAlertUseCase dismiss;
  late MockResetBackgroundServiceUseCase reset;
  late Signal<({String id, DeviceModel model})?> target;
  late MockStartDeviceSessionUseCase startSession;
  late BackgroundViewModel vm;

  final en = lookupAppLocalizations(const Locale('en'));
  const heating = HeatSession(
    model: DeviceModel.veazy,
    temperature: 180,
    target: 180,
    ready: false,
    batteryPercent: 72,
    boostTarget: 195,
  );
  const ready = HeatSession(
    model: DeviceModel.veazy,
    temperature: 180,
    target: 180,
    ready: true,
    batteryPercent: 72,
    boostTarget: 195,
  );

  setUpAll(() => registerFallbackValue(DeviceModel.veazy));

  setUpAll(
    () => registerFallbackValue(
      const BackgroundNotice(
        title: '',
        text: '',
        sessionChannel: '',
        readyChannel: '',
      ),
    ),
  );

  setUp(() {
    session = signal(null);
    lifecycle = signal(AppLifecycleState.resumed);
    final current = MockCurrentHeatSessionUseCase();
    when(
      () => current(previous: any(named: 'previous')),
    ).thenAnswer((_) => session.value);
    final lifecycleService = MockAppLifecycleService();
    when(() => lifecycleService.state).thenReturn(lifecycle);
    show = MockShowBackgroundSessionUseCase();
    when(() => show(any())).thenAnswer((_) async => right(unit));
    alert = MockAlertReadyUseCase();
    when(() => alert(any())).thenAnswer((_) async => right(unit));
    polling = MockSetPortablePollingUseCase();
    dismiss = MockDismissReadyAlertUseCase();
    when(() => dismiss()).thenAnswer((_) async => right(unit));
    reset = MockResetBackgroundServiceUseCase();
    when(() => reset()).thenAnswer((_) async => right(unit));
    target = signal(null);
    final sessionTarget = MockDeviceSessionTargetUseCase();
    when(() => sessionTarget()).thenAnswer((_) => target.value);
    startSession = MockStartDeviceSessionUseCase();
    when(() => startSession(any(), any())).thenAnswer((_) async => right(unit));
    vm = BackgroundViewModel(
      currentSession: current,
      showSession: show,
      alertReady: alert,
      dismissAlert: dismiss,
      resetService: reset,
      rules: BackgroundRules(),
      sessionTarget: sessionTarget,
      startDeviceSession: startSession,
      setPortablePolling: polling,
      lifecycle: lifecycleService,
      l10n: FakeL10nService(),
    );
  });

  tearDown(() => vm.dispose());

  test('notification texts', () {
    final notice = heating.notice(en);
    expect(notice.title, 'Veazy · 180°');
    expect(notice.text, 'Heating to 180° · battery 72%');
    expect(ready.readyNotice(en).title, 'Veazy is ready · 180°');
    expect(ready.readyNotice(en).text, 'Double-click for boost 195°');
  });

  test('keeps the device session running for the connected device', () {
    verifyNever(() => startSession(any(), any()));
    target.value = (id: 'vz', model: DeviceModel.veazy);
    verify(() => startSession('vz', DeviceModel.veazy)).called(1);
    target.value = null;
    target.value = (id: 'vz', model: DeviceModel.veazy);
    verify(() => startSession('vz', DeviceModel.veazy)).called(1);
  });

  test('stops a leftover service at start', () {
    verify(() => reset()).called(1);
  });

  test('shows the service while heating and hides it after', () {
    clearInteractions(show);
    session.value = heating;
    verify(() => show(heating.notice(en))).called(1);
    session.value = null;
    verify(() => show(null)).called(1);
  });

  test('alerts "ready" only once per heat-up and only in the background', () {
    session.value = heating;
    session.value = ready;
    verifyNever(() => alert(any()));

    // Seen in front: no alert for this heat-up. A new heat-up in the
    // background gets one.
    session.value = null;
    lifecycle.value = AppLifecycleState.paused;
    session.value = heating;
    session.value = ready;
    verify(() => alert(ready.readyNotice(en))).called(1);
    session.value = heating;
    session.value = ready;
    verifyNever(() => alert(any()));

    lifecycle.value = AppLifecycleState.resumed;
    verify(() => dismiss()).called(1);
  });

  group('portable polling', () {
    test('keeps polling while in front', () {
      verify(() => polling(active: true)).called(1);
      lifecycle.value = AppLifecycleState.inactive;
      verifyNever(() => polling(active: any(named: 'active')));
    });

    test('pauses in the background while nothing heats', () {
      lifecycle.value = AppLifecycleState.hidden;
      verify(() => polling(active: false)).called(1);
    });

    test('keeps polling in the background while a heater is on', () {
      session.value = heating;
      clearInteractions(polling);
      lifecycle.value = AppLifecycleState.paused;
      verifyNever(() => polling(active: false));
      session.value = null;
      verify(() => polling(active: false)).called(1);
    });
  });
}
