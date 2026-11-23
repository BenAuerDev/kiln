// Renders the README screenshots with sample data into docs/screenshots/.
//
//   flutter test tool/screenshots/readme_screenshots_test.dart --update-goldens
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:kiln/core/theme/kiln_theme_scope.dart';
import 'package:kiln/core/theme/kiln_tokens.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/models/quick_setup.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/portable/presentation/screens/portable_control_screen.dart';
import 'package:kiln/features/portable/presentation/screens/portable_setup_screen.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_control_view_model.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_setup_view_model.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_tab.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/presentation/screens/volcano_control_screen.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_control_view_model.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../test/features/devices/helpers/demo_badge_stub.dart';
import '../../test/features/portable/helpers/portable_fixtures.dart';
import '../../test/features/portable/presentation/presentation_mocks.dart';
import '../../test/features/volcano/mocks.dart' as volcano;

const _screen = Size(390, 844);

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Inter', [
    for (final weight in [400, 500, 600, 700]) 'assets/fonts/Inter-$weight.ttf',
  ]);
  await load('SpaceGrotesk', [
    for (final weight in [500, 600, 700])
      'assets/fonts/SpaceGrotesk-$weight.ttf',
  ]);
  await load('packages/obers_ui/lucide', [
    'packages/obers_ui/lib/src/foundation/icons/lucide.ttf',
  ]);
}

Future<void> _shoot(
  WidgetTester tester,
  Widget screen,
  KilnFinishTokens finish,
  String name,
) async {
  tester.view.physicalSize = _screen * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('screenshot'),
      child: KilnThemeScope(
        finish: finish,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: KilnFonts.body),
          child: OiApp(
            theme: buildKilnTheme(finish, Brightness.dark),
            darkTheme: buildKilnTheme(finish, Brightness.dark),
            themeMode: OiThemeMode.dark,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            home: MediaQuery(
              data: const MediaQueryData(
                size: _screen,
                devicePixelRatio: 3,
                disableAnimations: true,
                padding: EdgeInsets.only(top: 12),
              ),
              child: screen,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await expectLater(
    find.byKey(const Key('screenshot')),
    matchesGoldenFile('../../docs/screenshots/$name.png'),
  );
}

PortableStatus _veazyStatus({
  required HeaterMode heaterMode,
  bool ready = false,
}) => testStatus(
  target: 175,
  superBoost: 10,
  heaterMode: heaterMode,
).copyWith(batteryPercent: 72, setpointReached: ready);

void main() {
  setUpAll(() async {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
    registerFallbackValue(QuickSetup.flavour);
    registerFallbackValue(HeaterMode.off);
    registerFallbackValue(PortableTab.control);
    await _loadFonts();
  });

  setUp(registerDemoBadge);

  tearDown(sl.reset);

  BindingHarness portable(PortableStatus status) {
    final h = BindingHarness();
    when(() => h.startSession(any(), any())).thenAnswer((_) async {
      h.status.value = status;
      h.sessionActive.value = true;
      return right(unit);
    });
    h.activeDeviceId.value = deviceId;
    h.connectionStatus.value = ConnectionStatus.connected;
    return h;
  }

  testWidgets('veazy setup', (tester) async {
    final h = portable(_veazyStatus(heaterMode: HeaterMode.off));
    sl.registerFactory(
      () => PortableSetupViewModel(
        session: h.binding(),
        ladderService: PortableLadderService(),
        adjustBase: MockAdjustBaseTemperatureUseCase(),
        adjustBoost: MockAdjustBoostOffsetUseCase(),
        adjustSuperBoost: MockAdjustSuperBoostOffsetUseCase(),
        applyQuickSetup: MockApplyQuickSetupUseCase(),
        navigator: MockPortableNavigator(),
      ),
    );
    await _shoot(
      tester,
      const PortableSetupScreen(),
      KilnPalette.blue,
      'veazy-setup',
    );
  });

  testWidgets('veazy control', (tester) async {
    final h = portable(
      _veazyStatus(heaterMode: HeaterMode.normal, ready: true),
    );
    sl.registerFactory(
      () => PortableControlViewModel(
        session: h.binding(),
        ladderService: PortableLadderService(),
        adjustBase: MockAdjustBaseTemperatureUseCase(),
        setBase: MockSetBaseTemperatureUseCase(),
        toggleHeater: MockTogglePortableHeaterUseCase(),
        toggleBoost: MockTogglePortableBoostUseCase(),
        navigator: MockPortableNavigator(),
      ),
    );
    await _shoot(
      tester,
      const PortableControlScreen(),
      KilnPalette.blue,
      'veazy-control',
    );
  });

  testWidgets('volcano control', (tester) async {
    final repository = volcano.MockVolcanoRepository();
    final connection = volcano.MockConnectionRepository();
    final knownDevices = volcano.MockKnownDevicesRepository();
    final startSession = volcano.MockStartVolcanoSessionUseCase();
    final l10n = volcano.MockL10nService();
    when(() => repository.status).thenReturn(
      signal<VolcanoStatus?>(
        const VolcanoStatus(
          currentTemperature: 172,
          targetTemperature: 185,
          heaterOn: true,
          pumpOn: false,
          autoShutdown: true,
          fahrenheit: false,
          displayOnCooling: true,
          vibrationWhenReady: true,
        ),
      ),
    );
    when(() => repository.sessionActive).thenReturn(signal(true));
    when(() => connection.activeDeviceId).thenReturn(signal<String?>('AA'));
    when(
      () => connection.status,
    ).thenReturn(signal(ConnectionStatus.connected));
    when(() => knownDevices.byId(any())).thenReturn(null);
    when(() => startSession(any())).thenAnswer((_) async => right(unit));
    when(
      () => l10n.strings,
    ).thenReturn(lookupAppLocalizations(const Locale('en')));
    sl.registerFactory(
      () => VolcanoControlViewModel(
        repository: repository,
        connection: connection,
        knownDevices: knownDevices,
        startSession: startSession,
        stopSession: volcano.MockStopVolcanoSessionUseCase(),
        setTarget: volcano.MockSetVolcanoTargetUseCase(),
        adjustTarget: volcano.MockAdjustVolcanoTargetUseCase(),
        toggleHeater: volcano.MockToggleVolcanoHeaterUseCase(),
        togglePump: volcano.MockToggleVolcanoPumpUseCase(),
        haptics: volcano.MockHapticsService(),
        toasts: volcano.MockToastService(),
        l10n: l10n,
        navigator: volcano.MockVolcanoNavigator(),
      ),
    );
    await _shoot(
      tester,
      const VolcanoControlScreen(),
      KilnPalette.ember,
      'volcano-control',
    );
  });
}
