import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/finish_preference.dart';
import 'package:kiln/features/portable/domain/models/portable_settings.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_settings_view_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';
import '../presentation_mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
    registerFallbackValue(testSettings);
    registerFallbackValue(const MatchDevice());
  });

  late BindingHarness h;
  late MockFindPortableDeviceUseCase findDevice;
  late MockUpdatePortableSettingsUseCase updateSettings;
  late MockSetDeviceFinishUseCase setFinish;
  late MockForgetDeviceUseCase forgetDevice;
  late MockPortableNavigator navigator;
  late PortableSettingsViewModel vm;

  setUp(() async {
    h = BindingHarness();
    findDevice = MockFindPortableDeviceUseCase();
    updateSettings = MockUpdatePortableSettingsUseCase();
    setFinish = MockSetDeviceFinishUseCase();
    forgetDevice = MockForgetDeviceUseCase();
    navigator = MockPortableNavigator();
    vm = PortableSettingsViewModel(
      session: h.binding(),
      findDevice: findDevice,
      updateSettings: updateSettings,
      setFinish: setFinish,
      forgetDevice: forgetDevice,
      navigator: navigator,
      findingDuration: const Duration(milliseconds: 20),
    );
    await h.connect();
  });

  tearDown(() => vm.dispose());

  group('device settings', () {
    test('each switch writes its field and confirms', () async {
      when(() => updateSettings(any())).thenAnswer((_) async => right(unit));

      await vm.setChargeLimit(true);
      verify(
        () => updateSettings(testSettings.copyWith(ecoCharge: true)),
      ).called(1);

      await vm.setBatterySaver(true);
      verify(
        () => updateSettings(testSettings.copyWith(ecoVoltage: true)),
      ).called(1);

      await vm.setVibrateWhenReady(false);
      verify(
        () => updateSettings(testSettings.copyWith(vibrateWhenReady: false)),
      ).called(1);

      await vm.setBoostOnLeds(false);
      verify(
        () => updateSettings(testSettings.copyWith(boostVisualisation: false)),
      ).called(1);

      await vm.setFahrenheit(true);
      verify(
        () => updateSettings(testSettings.copyWith(fahrenheit: true)),
      ).called(1);

      h.verifySaved(5);
    });

    test('an unchanged value writes nothing', () async {
      await vm.setVibrateWhenReady(true);

      verifyNever(() => updateSettings(any()));
      h.verifyNoToast();
    });

    test('a queued change starts from the previous write', () async {
      when(() => updateSettings(any())).thenAnswer((invocation) async {
        h.status.value = h.status.value!.copyWith(
          settings: invocation.positionalArguments.first as PortableSettings,
        );
        return right(unit);
      });

      await Future.wait([vm.setChargeLimit(true), vm.setBatterySaver(true)]);

      verify(
        () => updateSettings(
          testSettings.copyWith(ecoCharge: true, ecoVoltage: true),
        ),
      ).called(1);
    });
  });

  test('find shows the finding state for a while', () async {
    when(() => findDevice()).thenAnswer((_) async => right(unit));

    await vm.findDevice();

    expect(vm.finding.value, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(vm.finding.value, isFalse);
    h.verifyNoToast();
  });

  test('a failed find shows the error', () async {
    when(
      () => findDevice(),
    ).thenAnswer((_) async => left(const AppError.notConnected()));

    await vm.findDevice();

    expect(vm.finding.value, isFalse);
    verify(
      () => h.toasts.show(strings.errorNotConnected, level: ToastLevel.error),
    ).called(1);
  });

  test('selecting a finish stores it for this device', () async {
    when(() => setFinish(any(), any())).thenAnswer((_) async => right(unit));

    await vm.selectFinish(const FixedFinish(DeviceFinish.pink));
    await vm.selectFinish(const MatchDevice());

    verify(
      () => setFinish(deviceId, const FixedFinish(DeviceFinish.pink)),
    ).called(1);
    verifyNever(() => setFinish(deviceId, const MatchDevice()));
    h.verifyNoToast();
  });

  group('forget', () {
    test('after confirming, forgets and goes to the devices', () async {
      when(() => navigator.confirmForget(any())).thenAnswer((_) async => true);
      when(() => forgetDevice(any())).thenAnswer((_) async => right(unit));

      await vm.forgetDevice();

      verify(() => navigator.confirmForget('Veazy')).called(1);
      verify(() => forgetDevice(deviceId)).called(1);
      verify(() => navigator.goToDevices()).called(1);
    });

    test('cancelling keeps the device', () async {
      when(() => navigator.confirmForget(any())).thenAnswer((_) async => false);

      await vm.forgetDevice();

      verifyNever(() => forgetDevice(any()));
      verifyNever(() => navigator.goToDevices());
    });

    test('an error stays on the screen', () async {
      when(() => navigator.confirmForget(any())).thenAnswer((_) async => true);
      when(
        () => forgetDevice(any()),
      ).thenAnswer((_) async => left(const AppError.storage()));

      await vm.forgetDevice();

      verifyNever(() => navigator.goToDevices());
      verify(
        () => h.toasts.show(strings.errorStorage, level: ToastLevel.error),
      ).called(1);
    });
  });

  test('back', () {
    vm.back();
    verify(() => navigator.back()).called(1);
  });
}
