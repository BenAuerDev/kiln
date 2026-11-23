import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:kiln/core/theme/kiln_theme_scope.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:obers_ui/obers_ui.dart';

/// Pumps [child] in a dark, phone-sized kiln app.
Future<void> pumpKiln(
  WidgetTester tester,
  Widget child, {
  bool disableAnimations = true,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    KilnThemeScope(
      finish: KilnPalette.blue,
      child: OiApp(
        theme: buildKilnTheme(KilnPalette.blue, Brightness.dark),
        darkTheme: buildKilnTheme(KilnPalette.blue, Brightness.dark),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}
