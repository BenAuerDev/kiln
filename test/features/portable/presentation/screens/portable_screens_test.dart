import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/quick_setup.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/portable/presentation/screens/portable_control_screen.dart';
import 'package:kiln/features/portable/presentation/screens/portable_settings_screen.dart';
import 'package:kiln/features/portable/presentation/screens/portable_setup_screen.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_control_view_model.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_settings_view_model.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_setup_view_model.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_tab.dart';
import 'package:kiln/features/portable/presentation/widgets/control/portable_heat_wisps.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';
import '../presentation_mocks.dart';
import '../pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
    registerFallbackValue(QuickSetup.flavour);
    registerFallbackValue(HeaterMode.off);
    registerFallbackValue(PortableTab.control);
    registerFallbackValue(testSettings);
  });

  late BindingHarness h;
  late MockPortableNavigator navigator;

  setUp(() {
    h = BindingHarness();
    navigator = MockPortableNavigator();
    h.activeDeviceId.value = deviceId;
    h.connectionStatus.value = ConnectionStatus.connected;
  });

  tearDown(sl.reset);

  group('setup', () {
    late MockAdjustBoostOffsetUseCase adjustBoost;
    late MockApplyQuickSetupUseCase applyQuickSetup;

    setUp(() {
      adjustBoost = MockAdjustBoostOffsetUseCase();
      applyQuickSetup = MockApplyQuickSetupUseCase();
      when(() => adjustBoost(any())).thenAnswer((_) async => right(some(16)));
      when(() => applyQuickSetup(any())).thenAnswer((_) async => right(unit));
      sl.registerFactory(
        () => PortableSetupViewModel(
          session: h.binding(savedFeedbackDelay: Duration.zero),
          ladderService: PortableLadderService(),
          adjustBase: MockAdjustBaseTemperatureUseCase(),
          adjustBoost: adjustBoost,
          adjustSuperBoost: MockAdjustSuperBoostOffsetUseCase(),
          applyQuickSetup: applyQuickSetup,
          navigator: navigator,
        ),
      );
    });

    testWidgets('shows the ladder and quick setups', (tester) async {
      await pumpKiln(tester, const PortableSetupScreen());

      expect(find.text('Veazy'), findsOneWidget);
      expect(find.text('Connected · 80% battery'), findsOneWidget);
      for (final text in ['Base', 'Boost', 'Superboost', '180°', '+15°']) {
        expect(find.text(text), findsWidgets);
      }
      expect(find.text('→ 195°'), findsOneWidget);
      expect(find.text('→ 210° max'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('175–195°'), findsOneWidget);
      expect(find.text('Control'), findsOneWidget);
    });

    testWidgets('buttons reach the view model', (tester) async {
      await pumpKiln(tester, const PortableSetupScreen());

      await tester.tap(find.bySemanticsLabel('Raise boost'));
      await tester.tap(find.text('Full'));
      await tester.tap(find.bySemanticsLabel('Veazy settings'));
      await tester.tap(find.text('Devices'));
      await tester.pump();

      verify(() => adjustBoost(1)).called(1);
      verify(() => applyQuickSetup(QuickSetup.full)).called(1);
      verify(() => navigator.openSettings()).called(1);
      verify(() => navigator.goToTab(PortableTab.devices)).called(1);
    });
  });

  group('control', () {
    late MockSetBaseTemperatureUseCase setBase;
    late MockTogglePortableBoostUseCase toggleBoost;

    setUp(() {
      setBase = MockSetBaseTemperatureUseCase();
      toggleBoost = MockTogglePortableBoostUseCase();
      when(() => setBase(any())).thenAnswer((_) async => right(some(195)));
      when(
        () => toggleBoost(),
      ).thenAnswer((_) async => left(const AppError.writeNotVerified('boost')));
      sl.registerFactory(
        () => PortableControlViewModel(
          session: h.binding(savedFeedbackDelay: Duration.zero),
          ladderService: PortableLadderService(),
          adjustBase: MockAdjustBaseTemperatureUseCase(),
          setBase: setBase,
          toggleHeater: MockTogglePortableHeaterUseCase(),
          toggleBoost: toggleBoost,
          navigator: navigator,
        ),
      );
    });

    testWidgets('shows the target when there is no live reading', (
      tester,
    ) async {
      await pumpKiln(tester, const PortableControlScreen());

      expect(find.text('kiln'), findsOneWidget);
      expect(find.text('Veazy · 80% battery'), findsOneWidget);
      expect(find.text('HEATER OFF'), findsOneWidget);
      expect(find.text('target temperature'), findsOneWidget);
      expect(find.text('180°'), findsNWidgets(2));
      for (final preset in ['175°', '185°', '195°', '205°']) {
        expect(find.text(preset), findsOneWidget);
      }
      expect(find.text('Heater off'), findsOneWidget);
      expect(find.text('Boost'), findsOneWidget);
    });

    testWidgets('shows the live reading while heating, with wisps', (
      tester,
    ) async {
      await pumpKiln(
        tester,
        const PortableControlScreen(),
        disableAnimations: false,
      );
      h.status.value = testStatus(
        heaterMode: HeaterMode.normal,
      ).copyWith(currentTemperature: 151.4);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('HEATING'), findsOneWidget);
      expect(find.text('151°'), findsOneWidget);
      expect(find.text('target 180 °C'), findsOneWidget);
      expect(find.byType(PortableHeatWisps), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('buttons reach the view model', (tester) async {
      await pumpKiln(tester, const PortableControlScreen());

      await tester.tap(find.text('195°'));
      await tester.tap(find.bySemanticsLabel('Boost'));
      await tester.pump();

      verify(() => setBase(195)).called(1);
      verify(() => toggleBoost()).called(1);
      verify(
        () => h.toasts.show(
          strings.errorWriteNotVerified,
          level: ToastLevel.error,
        ),
      ).called(1);
    });
  });

  group('settings', () {
    late MockUpdatePortableSettingsUseCase updateSettings;

    setUp(() {
      updateSettings = MockUpdatePortableSettingsUseCase();
      when(() => updateSettings(any())).thenAnswer((_) async => right(unit));
      when(() => navigator.confirmForget(any())).thenAnswer((_) async => false);
      sl.registerFactory(
        () => PortableSettingsViewModel(
          session: h.binding(savedFeedbackDelay: Duration.zero),
          findDevice: MockFindPortableDeviceUseCase(),
          updateSettings: updateSettings,
          setFinish: MockSetDeviceFinishUseCase(),
          forgetDevice: MockForgetDeviceUseCase(),
          navigator: navigator,
        ),
      );
    });

    testWidgets('shows every section without device check', (tester) async {
      await pumpKiln(
        tester,
        const PortableSettingsScreen(),
        size: const Size(390, 1400),
      );

      for (final text in [
        'Veazy settings',
        'Find my Veazy',
        'BATTERY',
        'Charge limit',
        'Battery saver',
        'DEVICE',
        'Vibrate when ready',
        'Show boost on LEDs',
        'Temperature unit',
        'APP THEME',
        'Match my device',
        'Ember',
        'Mono',
        'Forget this device',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.textContaining('device check'), findsNothing);
    });

    testWidgets('controls reach the view model', (tester) async {
      await pumpKiln(
        tester,
        const PortableSettingsScreen(),
        size: const Size(390, 1400),
      );

      await tester.tap(find.text('Charge limit'));
      await tester.tap(find.text('Forget this device'));
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();

      verify(
        () => updateSettings(testSettings.copyWith(ecoCharge: true)),
      ).called(1);
      verify(() => navigator.confirmForget('Veazy')).called(1);
      verify(() => navigator.back()).called(1);
    });
  });
}
