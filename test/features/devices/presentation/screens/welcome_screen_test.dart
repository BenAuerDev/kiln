import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/presentation/screens/welcome_screen.dart';
import 'package:kiln/features/devices/presentation/view_models/welcome_view_model.dart';
import 'package:kiln/features/devices/presentation/widgets/welcome/found_device_card.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_kiln.dart';

void main() {
  late MockScanRepository scan;
  late MockStartDeviceScanUseCase startScan;
  late Signal<List<DiscoveredDevice>> results;
  late Signal<bool> scanning;

  setUp(() {
    final settings = MockAppSettingsRepository();
    final stopScan = MockStopDeviceScanUseCase();
    final haptics = MockHapticsService();
    scan = MockScanRepository();
    startScan = MockStartDeviceScanUseCase();
    results = signal<List<DiscoveredDevice>>(const []);
    scanning = signal(false);
    when(() => settings.localeCode).thenReturn(signal<String?>(null));
    when(() => scan.results).thenReturn(results);
    when(() => scan.scanning).thenReturn(scanning);
    when(() => startScan()).thenAnswer((_) async {
      scanning.value = true;
      return right(unit);
    });
    when(() => stopScan()).thenAnswer((_) async => right(unit));
    when(() => haptics.tick()).thenAnswer((_) async {});
    sl.registerFactory(
      () => WelcomeViewModel(
        settings: settings,
        scan: scan,
        startScan: startScan,
        stopScan: stopScan,
        connectDevice: MockConnectDeviceUseCase(),
        completeWelcome: MockCompleteWelcomeUseCase(),
        setLocale: MockSetAppLocaleUseCase(),
        l10n: FakeL10nService(),
        haptics: haptics,
        toast: MockToastService(),
        navigator: MockDevicesNavigator(),
      ),
    );
  });

  tearDown(sl.reset);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpKiln(tester, const WelcomeScreen());
    await tester.pump();
  }

  testWidgets('explains Bluetooth first and shows the unofficial notice', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text("Let's find your vaporizer"), findsOneWidget);
    expect(
      find.text('Unofficial app, not affiliated with Storz & Bickel.'),
      findsOneWidget,
    );
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('DE'), findsOneWidget);
    verifyNever(() => startScan());
  });

  testWidgets('continue scans and shows found devices', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Looking around…'), findsOneWidget);

    results.value = const [discoveredVenty];
    await tester.pump();
    expect(find.text('Found one'), findsOneWidget);
    expect(find.byType(FoundDeviceCard), findsOneWidget);
    expect(
      find.text('Unofficial app, not affiliated with Storz & Bickel.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders a still radar with reduced motion', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpScreen(tester);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
  });
}
