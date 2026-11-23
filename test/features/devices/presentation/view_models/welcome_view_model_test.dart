import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/presentation/view_models/welcome_step.dart';
import 'package:kiln/features/devices/presentation/view_models/welcome_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockAppSettingsRepository settings;
  late MockScanRepository scan;
  late MockStartDeviceScanUseCase startScan;
  late MockStopDeviceScanUseCase stopScan;
  late MockConnectDeviceUseCase connectDevice;
  late MockCompleteWelcomeUseCase completeWelcome;
  late MockSetAppLocaleUseCase setLocale;
  late MockHapticsService haptics;
  late MockToastService toast;
  late MockDevicesNavigator navigator;
  late Signal<String?> localeCode;
  late Signal<List<DiscoveredDevice>> results;
  late Signal<bool> scanning;
  late WelcomeViewModel vm;

  setUpAll(() {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
  });

  setUp(() {
    settings = MockAppSettingsRepository();
    scan = MockScanRepository();
    startScan = MockStartDeviceScanUseCase();
    stopScan = MockStopDeviceScanUseCase();
    connectDevice = MockConnectDeviceUseCase();
    completeWelcome = MockCompleteWelcomeUseCase();
    setLocale = MockSetAppLocaleUseCase();
    haptics = MockHapticsService();
    toast = MockToastService();
    navigator = MockDevicesNavigator();
    localeCode = signal<String?>(null);
    results = signal<List<DiscoveredDevice>>(const []);
    scanning = signal(false);
    when(() => settings.localeCode).thenReturn(localeCode);
    when(() => scan.results).thenReturn(results);
    when(() => scan.scanning).thenReturn(scanning);
    when(() => startScan()).thenAnswer((_) async {
      scanning.value = true;
      return right(unit);
    });
    when(() => stopScan()).thenAnswer((_) async => right(unit));
    when(() => completeWelcome()).thenAnswer((_) async => right(unit));
    when(() => setLocale(any())).thenAnswer((_) async => right(unit));
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    vm = WelcomeViewModel(
      settings: settings,
      scan: scan,
      startScan: startScan,
      stopScan: stopScan,
      connectDevice: connectDevice,
      completeWelcome: completeWelcome,
      setLocale: setLocale,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
    );
  });

  tearDown(() => vm.dispose());

  test('starts on the explainer and scans on continue', () async {
    expect(vm.step.value, WelcomeStep.intro);
    verifyNever(() => startScan());

    await vm.start();

    expect(vm.step.value, WelcomeStep.scan);
    expect(vm.scanState.value, WelcomeScanState.looking);
    verify(() => startScan()).called(1);
  });

  test('scan state follows results and the end of the scan', () async {
    await vm.start();

    results.value = const [discoveredVenty];
    expect(vm.scanState.value, WelcomeScanState.found);

    results.value = const [];
    scanning.value = false;
    expect(vm.scanState.value, WelcomeScanState.nothing);
  });

  test('a scan error becomes a toast', () async {
    when(
      () => startScan(),
    ).thenAnswer((_) async => left(const AppError.bluetoothUnavailable()));

    await vm.start();

    verify(
      () => toast.show(
        'Bluetooth is off or not available.',
        level: ToastLevel.error,
      ),
    ).called(1);
  });

  test('connecting completes the welcome and opens the device', () async {
    final known = KnownDevice(
      id: discoveredVenty.id,
      name: discoveredVenty.name,
      model: DeviceModel.venty,
    );
    when(() => connectDevice(any())).thenAnswer((_) async => right(known));

    await vm.connect(discoveredVenty);

    verifyInOrder([
      () => connectDevice(discoveredVenty.id),
      () => completeWelcome(),
      () => navigator.goToDeviceHome(DeviceModel.venty),
    ]);
    expect(vm.connectingId.value, isNull);
  });

  test('a Crafty+ completes the welcome and lands on devices', () async {
    when(() => connectDevice(any())).thenAnswer(
      (_) async => right(
        const KnownDevice(id: 'c', name: 'c', model: DeviceModel.craftyPlus),
      ),
    );

    await vm.connect(discoveredVenty);

    verify(() => completeWelcome()).called(1);
    verify(() => toast.show("Crafty+ isn't supported yet.")).called(1);
    verify(() => navigator.goToDevices()).called(1);
  });

  test('a failed connect keeps the welcome open', () async {
    when(
      () => connectDevice(any()),
    ).thenAnswer((_) async => left(const AppError.connectionFailed()));

    await vm.connect(discoveredVenty);

    verifyNever(() => completeWelcome());
    verify(() => haptics.warning()).called(1);
    verify(
      () => toast.show("Couldn't connect. Try again.", level: ToastLevel.error),
    ).called(1);
  });

  test('a failed welcome completion stays on the welcome', () async {
    when(() => connectDevice(any())).thenAnswer(
      (_) async => right(
        KnownDevice(
          id: discoveredVenty.id,
          name: discoveredVenty.name,
          model: DeviceModel.venty,
        ),
      ),
    );
    when(
      () => completeWelcome(),
    ).thenAnswer((_) async => left(const AppError.storage()));

    await vm.connect(discoveredVenty);

    verify(() => toast.show(any(), level: ToastLevel.error)).called(1);
    verifyNever(() => navigator.goToDeviceHome(any()));
    verifyNever(() => navigator.goToDevices());
    expect(vm.connectingId.value, isNull);
  });

  test('skip stays on the welcome when completing it fails', () async {
    when(
      () => completeWelcome(),
    ).thenAnswer((_) async => left(const AppError.storage()));

    await vm.skip();

    verify(() => toast.show(any(), level: ToastLevel.error)).called(1);
    verifyNever(() => navigator.goToDevices());
  });

  test('skip completes the welcome and opens devices', () async {
    await vm.skip();

    verify(() => stopScan()).called(1);
    verify(() => completeWelcome()).called(1);
    verify(() => navigator.goToDevices()).called(1);
  });

  test('language follows the override, then the app locale', () async {
    expect(vm.languageCode.value, 'en');

    localeCode.value = 'de';
    expect(vm.languageCode.value, 'de');

    await vm.selectLanguage('de');
    verifyNever(() => setLocale(any()));

    await vm.selectLanguage('en');
    verify(() => setLocale('en')).called(1);
  });
}
