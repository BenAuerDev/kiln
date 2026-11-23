import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import 'kiln_palette.dart';
import 'kiln_tokens.dart';

abstract final class KilnFonts {
  static const body = 'Inter';
  static const display = 'SpaceGrotesk';
  static const tabular = [FontFeature.tabularFigures()];
}

OiThemeData buildKilnTheme(KilnFinishTokens finish, Brightness brightness) {
  final accent = finish.resolve(brightness);
  final surfaces = kilnSurfaces(brightness);
  final base = OiThemeData.fromBrand(
    color: accent.accent,
    brightness: brightness,
    fontFamily: KilnFonts.body,
    radiusPreference: OiRadiusPreference.rounded,
  );
  return base.copyWith(
    colors: base.colors.copyWith(
      primary: OiColorSwatch.from(
        accent.accent,
      ).copyWith(foreground: accent.onAccent),
      background: surfaces.background,
      surface: surfaces.surface,
      surfaceSubtle: surfaces.surfaceRaised,
      surfaceHover: surfaces.surfaceRaised,
      text: surfaces.text,
      textSubtle: surfaces.muted,
      textOnPrimary: accent.onAccent,
      border: surfaces.border,
      borderSubtle: surfaces.border,
    ),
    textTheme: _textTheme(base.textTheme),
  );
}

KilnSurfaceTokens kilnSurfaces(Brightness brightness) =>
    brightness == Brightness.dark
    ? KilnPalette.darkSurfaces
    : KilnPalette.lightSurfaces;

OiTextTheme _textTheme(OiTextTheme base) {
  TextStyle display(TextStyle style) => style.copyWith(
    fontFamily: KilnFonts.display,
    fontFeatures: KilnFonts.tabular,
    letterSpacing: -0.4,
  );
  return base.copyWith(
    display: display(base.display),
    h1: display(base.h1),
    h2: display(base.h2),
    h3: display(base.h3),
    h4: display(base.h4),
  );
}
