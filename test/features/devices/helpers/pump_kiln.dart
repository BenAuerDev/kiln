import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:kiln/core/theme/kiln_theme_scope.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:obers_ui/obers_ui.dart';

Future<void> pumpKiln(WidgetTester tester, Widget child) => tester.pumpWidget(
  KilnThemeScope(
    finish: KilnPalette.ember,
    child: OiApp(
      theme: buildKilnTheme(KilnPalette.ember, Brightness.light),
      darkTheme: buildKilnTheme(KilnPalette.ember, Brightness.dark),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Center(child: child),
    ),
  ),
);
