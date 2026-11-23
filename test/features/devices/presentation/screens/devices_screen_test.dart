import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/services/device_list_service.dart';
import 'package:kiln/features/devices/presentation/screens/devices_screen.dart';
import 'package:kiln/features/devices/presentation/view_models/devices_view_model.dart';
import 'package:kiln/features/devices/presentation/widgets/devices/known_device_card.dart';
import 'package:kiln/features/devices/presentation/widgets/devices/nearby_device_card.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_kiln.dart';

void main() {
  late MockStartDeviceScanUseCase startScan;
  late Signal<bool> scanning;

  setUp(() {
    final knownDevices = MockKnownDevicesRepository();
    final connection = MockConnectionRepository();
    final scan = MockScanRepository();
    final stopScan = MockStopDeviceScanUseCase();
    startScan = MockStartDeviceScanUseCase();
    scanning = signal(false);
    final active = volcano.copyWith(lastConnectedAt: fixedNow);
    when(() => knownDevices.devices).thenReturn(
      signal<List<KnownDevice>>([
        active,
        veazy.copyWith(lastConnectedAt: lastWeek),
      ]),
    );
    when(() => knownDevices.activeDevice).thenReturn(signal(active));
    when(
      () => connection.activeDeviceId,
    ).thenReturn(signal<String?>(volcano.id));
    when(
      () => connection.status,
    ).thenReturn(signal(ConnectionStatus.connected));
    when(
      () => scan.results,
    ).thenReturn(signal<List<DiscoveredDevice>>(const [discoveredVenty]));
    when(() => scan.scanning).thenReturn(scanning);
    when(() => startScan()).thenAnswer((_) async {
      scanning.value = true;
      return right(unit);
    });
    when(() => stopScan()).thenAnswer((_) async => right(unit));
    sl.registerFactory(
      () => DevicesViewModel(
        knownDevices: knownDevices,
        connection: connection,
        scan: scan,
        listService: const DeviceListService(),
        startScan: startScan,
        stopScan: stopScan,
        connectDevice: MockConnectDeviceUseCase(),
        disconnectDevice: MockDisconnectDeviceUseCase(),
        forgetDevice: MockForgetDeviceUseCase(),
        l10n: FakeL10nService(),
        haptics: MockHapticsService(),
        toast: MockToastService(),
        navigator: MockDevicesNavigator(),
        clock: () => fixedNow,
      ),
    );
  });

  tearDown(sl.reset);

  testWidgets('lists known and nearby devices and scans on open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpKiln(tester, const DevicesScreen());
    await tester.pump();

    verify(() => startScan()).called(1);
    expect(find.byType(KnownDeviceCard), findsNWidgets(2));
    expect(find.byType(NearbyDeviceCard), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Last used 7 days ago'), findsOneWidget);
    expect(find.text('SCANNING NEARBY'), findsOneWidget);
    expect(find.bySemanticsLabel('Back to control'), findsOneWidget);
    expect(find.textContaining('Not affiliated'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
