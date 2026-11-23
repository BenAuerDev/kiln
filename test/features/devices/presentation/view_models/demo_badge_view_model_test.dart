import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/presentation/view_models/demo_badge_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockKnownDevicesRepository knownDevices;
  late MockAppSettingsRepository settings;
  late MockLeaveDemoUseCase leaveDemo;
  late MockToastService toast;
  late MockDevicesNavigator navigator;
  late Signal<KnownDevice?> activeDevice;
  late Signal<bool> welcomeCompleted;
  late Signal<List<KnownDevice>> devices;
  late DemoBadgeViewModel vm;

  const demo = KnownDevice(
    id: 'demo:veazy',
    name: 'kiln demo',
    model: DeviceModel.veazy,
  );

  setUpAll(() => registerFallbackValue(ToastLevel.info));

  setUp(() {
    knownDevices = MockKnownDevicesRepository();
    settings = MockAppSettingsRepository();
    leaveDemo = MockLeaveDemoUseCase();
    toast = MockToastService();
    navigator = MockDevicesNavigator();
    activeDevice = signal(demo);
    welcomeCompleted = signal(true);
    devices = signal(const []);
    when(() => knownDevices.devices).thenReturn(devices);
    final haptics = MockHapticsService();
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => knownDevices.activeDevice).thenReturn(activeDevice);
    when(() => settings.welcomeCompleted).thenReturn(welcomeCompleted);
    when(() => leaveDemo()).thenAnswer((_) async => right(some(unit)));
    vm = DemoBadgeViewModel(
      knownDevices: knownDevices,
      settings: settings,
      leaveDemo: leaveDemo,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
    );
  });

  tearDown(() => vm.dispose());

  test('is visible only while a demo device is active', () {
    expect(vm.visible.value, isTrue);
    activeDevice.value = veazy;
    expect(vm.visible.value, isFalse);
    activeDevice.value = null;
    expect(vm.visible.value, isFalse);
  });

  test('leave goes to the devices once the welcome is done', () async {
    await vm.leave();
    verify(() => leaveDemo()).called(1);
    verify(() => navigator.goToDevices()).called(1);
  });

  test('leave goes back to the welcome if it was never completed', () async {
    welcomeCompleted.value = false;
    await vm.leave();
    verify(() => navigator.goToWelcome()).called(1);
  });

  test(
    'leave goes to the devices when a real device was paired meanwhile',
    () async {
      welcomeCompleted.value = false;
      devices.value = const [veazy];
      await vm.leave();
      verify(() => navigator.goToDevices()).called(1);
    },
  );

  test('a failed leave shows a toast and stays', () async {
    when(
      () => leaveDemo(),
    ).thenAnswer((_) async => left(const AppError.connectionFailed()));
    await vm.leave();
    verify(() => toast.show(any(), level: ToastLevel.error)).called(1);
    verifyNever(() => navigator.goToDevices());
  });
}
