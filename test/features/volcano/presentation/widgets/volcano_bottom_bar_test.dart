import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:kiln/core/theme/kiln_theme_scope.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_tab.dart';
import 'package:kiln/features/volcano/presentation/widgets/volcano_bottom_bar.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:obers_ui/obers_ui.dart';

void main() {
  testWidgets('shows Control and Devices and reports taps', (tester) async {
    final selected = <VolcanoTab>[];
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
          home: Align(
            alignment: Alignment.bottomCenter,
            child: VolcanoBottomBar(
              current: VolcanoTab.control,
              onSelect: selected.add,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Control'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('Setup'), findsNothing);

    await tester.tap(find.text('Devices'));
    await tester.pump();

    expect(selected, [VolcanoTab.devices]);
  });
}
