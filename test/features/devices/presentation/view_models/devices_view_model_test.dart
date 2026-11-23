import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/models/known_device_entry.dart';
import 'package:kiln/features/devices/domain/services/device_list_service.dart';
import 'package:kiln/features/devices/presentation/view_models/devices_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockKnownDevicesRepository knownDevices;
  late MockConnectionRepository connection;
  late MockScanRepository scan;
  late MockStartDeviceScanUseCase startScan;
  late MockStopDeviceScanUseCase stopScan;
  late MockConnectDeviceUseCase connectDevice;
  late MockDisconnectDeviceUseCase disconnectDevice;
  late MockForgetDeviceUseCase forgetDevice;
  late MockHapticsService haptics;
  late MockToastService toast;
  late MockDevicesNavigator navigator;
  late Signal<List<KnownDevice>> devices;
  late Signal<KnownDevice?> active;
  late Signal<String?> activeId;
  late Signal<ConnectionStatus> status;
  late Signal<List<DiscoveredDevice>> results;
  late Signal<bool> scanning;
  late DevicesViewModel vm;

  setUpAll(() {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
  });

  setUp(() {
    knownDevices = MockKnownDevicesRepository();
    connection = MockConnectionRepository();
    scan = MockScanRepository();
    startScan = MockStartDeviceScanUseCase();
    stopScan = MockStopDeviceScanUseCase();
    connectDevice = MockConnectDeviceUseCase();
    disconnectDevice = MockDisconnectDeviceUseCase();
    forgetDevice = MockForgetDeviceUseCase();
    haptics = MockHapticsService();
    toast = MockToastService();
    navigator = MockDevicesNavigator();
    devices = signal<List<KnownDevice>>(const [veazy]);
    active = signal<KnownDevice?>(null);
    activeId = signal<String?>(null);
    status = signal(ConnectionStatus.disconnected);
    results = signal<List<DiscoveredDevice>>(const [discoveredVenty]);
    scanning = signal(false);
    when(() => knownDevices.devices).thenReturn(devices);
    when(() => knownDevices.activeDevice).thenReturn(active);
    when(() => knownDevices.byId(veazy.id)).thenReturn(veazy);
    when(() => connection.activeDeviceId).thenReturn(activeId);
    when(() => connection.status).thenReturn(status);
    when(() => scan.results).thenReturn(results);
    when(() => scan.scanning).thenReturn(scanning);
    when(() => startScan()).thenAnswer((_) async => right(unit));
    when(() => stopScan()).thenAnswer((_) async => right(unit));
    when(() => disconnectDevice()).thenAnswer((_) async => right(unit));
    when(() => forgetDevice(any())).thenAnswer((_) async => right(unit));
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    vm = DevicesViewModel(
      knownDevices: knownDevices,
      connection: connection,
      scan: scan,
      listService: const DeviceListService(),
      startScan: startScan,
      stopScan: stopScan,
      connectDevice: connectDevice,
      disconnectDevice: disconnectDevice,
      forgetDevice: forgetDevice,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
      clock: () => fixedNow,
    );
  });

  tearDown(() => vm.dispose());

  test('lists known and new nearby devices', () {
    activeId.value = veazy.id;
    status.value = ConnectionStatus.connecting;

    expect(vm.knownDevices.value.single.status, ConnectionStatus.connecting);
    expect(vm.nearby.value, [discoveredVenty]);

    results.value = const [
      DiscoveredDevice(
        id: 'veazy-id',
        name: 'S&B VZ123456',
        model: DeviceModel.veazy,
        rssi: -50,
      ),
    ];
    expect(vm.nearby.value, isEmpty);
  });

  test('pairing a portable connects and opens its home', () async {
    final known = KnownDevice(
      id: discoveredVenty.id,
      name: discoveredVenty.name,
      model: DeviceModel.venty,
    );
    when(() => connectDevice(any())).thenAnswer((_) async => right(known));

    await vm.pair(discoveredVenty);

    verify(() => connectDevice(discoveredVenty.id)).called(1);
    verify(() => haptics.success()).called(1);
    verify(() => navigator.goToDeviceHome(DeviceModel.venty)).called(1);
    expect(vm.connectingId.value, isNull);
  });

  test('a Crafty+ connects but stays with a toast', () async {
    const crafty = KnownDevice(
      id: 'c',
      name: 'STORZ&BICKEL',
      model: DeviceModel.craftyPlus,
    );
    when(() => connectDevice(any())).thenAnswer((_) async => right(crafty));

    await vm.openKnown(const KnownDeviceEntry(device: crafty));

    verifyNever(() => navigator.goToDeviceHome(any()));
    verify(() => toast.show("Crafty+ isn't supported yet.")).called(1);
  });

  test('a failed connect warns and shows the error', () async {
    when(
      () => connectDevice(any()),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    await vm.openKnown(const KnownDeviceEntry(device: veazy));

    verify(() => haptics.warning()).called(1);
    verify(
      () => toast.show(
        "The device didn't answer in time.",
        level: ToastLevel.error,
      ),
    ).called(1);
    verifyNever(() => navigator.goToDeviceHome(any()));
  });

  test('tapping the connected device opens it without reconnecting', () async {
    await vm.openKnown(
      const KnownDeviceEntry(device: veazy, status: ConnectionStatus.connected),
    );

    verifyNever(() => connectDevice(any()));
    verify(() => navigator.goToDeviceHome(DeviceModel.veazy)).called(1);
  });

  test('forget asks first, then forgets with a toast', () async {
    vm.askForget(veazy.id);
    expect(vm.confirmingForgetId.value, veazy.id);

    vm.cancelForget();
    expect(vm.confirmingForgetId.value, isNull);

    vm.askForget(veazy.id);
    await vm.confirmForget(veazy.id);

    expect(vm.confirmingForgetId.value, isNull);
    verify(() => forgetDevice(veazy.id)).called(1);
    verify(() => toast.show('Veazy forgotten')).called(1);
  });

  test('back is offered only for a connected, supported device', () {
    expect(vm.canGoBack.value, isFalse);

    active.value = veazy;
    status.value = ConnectionStatus.connected;
    expect(vm.canGoBack.value, isTrue);

    vm.goBack();
    verify(() => navigator.goToDeviceHome(DeviceModel.veazy)).called(1);

    status.value = ConnectionStatus.reconnecting;
    expect(vm.canGoBack.value, isFalse);
  });

  test('scan errors become a toast', () async {
    when(
      () => startScan(),
    ).thenAnswer((_) async => left(const AppError.permissionDenied()));

    await vm.scan();

    verify(
      () => toast.show(
        'kiln needs Bluetooth permission to talk to your device.',
        level: ToastLevel.error,
      ),
    ).called(1);
  });

  test('dispose stops a running scan', () {
    scanning.value = true;

    vm.dispose();
    vm = DevicesViewModel(
      knownDevices: knownDevices,
      connection: connection,
      scan: scan,
      listService: const DeviceListService(),
      startScan: startScan,
      stopScan: stopScan,
      connectDevice: connectDevice,
      disconnectDevice: disconnectDevice,
      forgetDevice: forgetDevice,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
    );

    verify(() => stopScan()).called(1);
  });

  test('openDemo opens the demo picker', () {
    vm.openDemo();
    verify(() => navigator.openDemo()).called(1);
  });
}
