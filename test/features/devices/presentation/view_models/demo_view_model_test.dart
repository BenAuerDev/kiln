import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/router/route_paths.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/presentation/view_models/demo_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAppSettingsRepository settings;
  late MockStartDemoUseCase startDemo;
  late MockHapticsService haptics;
  late MockToastService toast;
  late MockDevicesNavigator navigator;
  late Signal<bool> welcomeCompleted;
  late Signal<List<KnownDevice>> devices;
  late DemoViewModel vm;

  setUpAll(() {
    registerFallbackValue(DeviceModel.veazy);
    registerFallbackValue(ToastLevel.info);
  });

  setUp(() {
    settings = MockAppSettingsRepository();
    startDemo = MockStartDemoUseCase();
    haptics = MockHapticsService();
    toast = MockToastService();
    navigator = MockDevicesNavigator();
    welcomeCompleted = signal(true);
    when(() => settings.welcomeCompleted).thenReturn(welcomeCompleted);
    devices = signal(const []);
    final knownDevices = MockKnownDevicesRepository();
    when(() => knownDevices.devices).thenReturn(devices);
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    vm = DemoViewModel(
      settings: settings,
      knownDevices: knownDevices,
      startDemo: startDemo,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
    );
  });

  test('offers Volcano Hybrid, Venty and Veazy', () {
    expect(vm.models, [
      DeviceModel.volcanoHybrid,
      DeviceModel.venty,
      DeviceModel.veazy,
    ]);
  });

  test('start opens the device home of the demo device', () async {
    when(() => startDemo(DeviceModel.venty)).thenAnswer(
      (_) async => right(
        const KnownDevice(
          id: 'demo:venty',
          name: 'kiln demo',
          model: DeviceModel.venty,
        ),
      ),
    );

    final starting = vm.start(DeviceModel.venty);
    expect(vm.startingModel.value, DeviceModel.venty);
    await starting;

    expect(vm.startingModel.value, isNull);
    verify(() => navigator.goToDeviceHome(DeviceModel.venty)).called(1);
    verify(() => haptics.success()).called(1);
  });

  test('a failed start shows a toast and stays', () async {
    when(
      () => startDemo(any()),
    ).thenAnswer((_) async => left(const AppError.connectionFailed()));

    await vm.start(DeviceModel.veazy);

    verify(() => toast.show(any(), level: ToastLevel.error)).called(1);
    verifyNever(() => navigator.goToDeviceHome(any()));
  });

  test('ignores a second start while one runs', () async {
    when(
      () => startDemo(any()),
    ).thenAnswer((_) async => left(const AppError.connectionFailed()));
    final first = vm.start(DeviceModel.veazy);
    await vm.start(DeviceModel.venty);
    await first;
    verify(() => startDemo(any())).called(1);
  });

  test('back falls back to the devices or the welcome', () {
    vm.back();
    verify(() => navigator.back(fallback: RoutePaths.devices)).called(1);
    welcomeCompleted.value = false;
    vm.back();
    verify(() => navigator.back(fallback: RoutePaths.welcome)).called(1);
    devices.value = const [
      KnownDevice(id: 'real', name: 'S&B VZ1', model: DeviceModel.veazy),
    ];
    vm.back();
    verify(() => navigator.back(fallback: RoutePaths.devices)).called(1);
  });
}
