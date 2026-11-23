import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:kiln/core/theme/kiln_theme_scope.dart';
import 'package:kiln/core/widgets/kiln_counting_temperature.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:obers_ui/obers_ui.dart';

void main() {
  late ValueNotifier<double> reading;

  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) =>
      tester.pumpWidget(
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
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: ValueListenableBuilder<double>(
                valueListenable: reading,
                builder: (_, celsius, _) => KilnCountingTemperature(
                  celsius: celsius,
                  semanticsLabel: 'Current temperature',
                ),
              ),
            ),
          ),
        ),
      );

  setUp(() => reading = ValueNotifier(151));

  testWidgets('starts at the first reading, not at zero', (tester) async {
    await pump(tester);

    expect(find.text('151°'), findsOneWidget);
  });

  testWidgets('counts through the degrees to the next reading', (tester) async {
    await pump(tester);

    reading.value = 155;
    await tester.pump();
    await tester.pump(KilnCountingTemperature.duration ~/ 4);

    final shown = tester
        .widgetList<OiLabel>(find.byType(OiLabel))
        .map((label) => label.text)
        .single;
    expect(['152°', '153°', '154°'], contains(shown));

    await tester.pumpAndSettle();
    expect(find.text('155°'), findsOneWidget);
  });

  testWidgets('jumps straight to the reading with reduce motion', (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);

    reading.value = 155;
    await tester.pump();
    await tester.pump();

    expect(find.text('155°'), findsOneWidget);
  });
}
