import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:kiln/core/theme/kiln_theme_scope.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/presentation/screens/volcano_control_screen.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_control_view_model.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository repository;
  late MockConnectionRepository connection;
  late MockKnownDevicesRepository knownDevices;
  late MockAdjustVolcanoTargetUseCase adjustTarget;
  late MockSetVolcanoTargetUseCase setTarget;
  late MockToggleVolcanoPumpUseCase togglePump;
  late MockHapticsService haptics;
  late MockToastService toasts;
  late MockL10nService l10n;
  late MockStartVolcanoSessionUseCase startSession;

  setUp(() {
    repository = MockVolcanoRepository();
    connection = MockConnectionRepository();
    knownDevices = MockKnownDevicesRepository();
    adjustTarget = MockAdjustVolcanoTargetUseCase();
    setTarget = MockSetVolcanoTargetUseCase();
    togglePump = MockToggleVolcanoPumpUseCase();
    haptics = MockHapticsService();
    toasts = MockToastService();
    l10n = MockL10nService();
    startSession = MockStartVolcanoSessionUseCase();

    when(
      () => repository.status,
    ).thenReturn(signal<VolcanoStatus?>(sampleStatus));
    when(() => repository.sessionActive).thenReturn(signal(true));
    when(() => connection.activeDeviceId).thenReturn(signal<String?>('AA'));
    when(
      () => connection.status,
    ).thenReturn(signal(ConnectionStatus.connected));
    when(() => knownDevices.byId('AA')).thenReturn(null);
    when(() => startSession('AA')).thenAnswer((_) async => right(unit));
    when(
      () => l10n.strings,
    ).thenReturn(lookupAppLocalizations(const Locale('en')));
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => adjustTarget(any())).thenAnswer((_) async => right(some(186)));
    when(() => setTarget(any())).thenAnswer((_) async => right(some(200)));
    when(() => togglePump()).thenAnswer((_) async => right(true));

    sl.registerFactory(
      () => VolcanoControlViewModel(
        repository: repository,
        connection: connection,
        knownDevices: knownDevices,
        startSession: startSession,
        stopSession: MockStopVolcanoSessionUseCase(),
        setTarget: setTarget,
        adjustTarget: adjustTarget,
        toggleHeater: MockToggleVolcanoHeaterUseCase(),
        togglePump: togglePump,
        haptics: haptics,
        toasts: toasts,
        l10n: l10n,
        navigator: MockVolcanoNavigator(),
        savedFeedbackDelay: Duration.zero,
      ),
    );
  });

  tearDown(sl.reset);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      KilnThemeScope(
        finish: KilnPalette.ember,
        child: OiApp(
          theme: buildKilnTheme(KilnPalette.ember, Brightness.dark),
          darkTheme: buildKilnTheme(KilnPalette.ember, Brightness.dark),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: VolcanoControlScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows status, presets and toggles', (tester) async {
    await pumpScreen(tester);

    expect(find.text('97°'), findsOneWidget);
    expect(find.text('185°'), findsWidgets);
    expect(find.text('HEATING'), findsOneWidget);
    for (final preset in ['170°', '200°', '215°']) {
      expect(find.text(preset), findsOneWidget);
    }
    expect(find.text('Heater on'), findsOneWidget);
    expect(find.text('Air off'), findsOneWidget);
    expect(find.textContaining('Volcano Hybrid · connected'), findsOneWidget);
  });

  testWidgets('buttons call the view model', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsLabel('Raise target temperature'));
    await tester.tap(find.text('200°'));
    await tester.tap(find.text('Air off'));
    await tester.pump();

    verify(() => adjustTarget(1)).called(1);
    verify(() => setTarget(200)).called(1);
    verify(() => togglePump()).called(1);
  });
}
