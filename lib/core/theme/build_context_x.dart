import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import 'kiln_theme.dart';
import 'kiln_theme_scope.dart';
import 'kiln_tokens.dart';

extension BuildContextX on BuildContext {
  KilnTokens get kiln {
    final brightness = OiTheme.of(this).brightness;
    return KilnTokens(
      accent: KilnThemeScope.of(this).resolve(brightness),
      surfaces: kilnSurfaces(brightness),
    );
  }
}
