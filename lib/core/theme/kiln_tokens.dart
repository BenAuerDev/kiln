import 'package:flutter/widgets.dart';

/// Accent tokens for one finish in one brightness.
class KilnAccentTokens {
  const KilnAccentTokens({
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.gradientStart,
    required this.gradientEnd,
    required this.glow,
  });

  final Color accent;

  /// Accent for small text; darker on light backgrounds for contrast.
  final Color accentText;
  final Color onAccent;
  final Color gradientStart;
  final Color gradientEnd;
  final Color glow;

  LinearGradient get gradient =>
      LinearGradient(colors: [gradientStart, gradientEnd]);
}

class KilnFinishTokens {
  const KilnFinishTokens({required this.dark, required this.light});

  final KilnAccentTokens dark;
  final KilnAccentTokens light;

  KilnAccentTokens resolve(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Neutral surface tokens from the mockups that Obers has no slot for.
class KilnSurfaceTokens {
  const KilnSurfaceTokens({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.text,
    required this.muted,
    required this.border,
    required this.track,
    required this.low,
    required this.toastBackground,
    required this.toastText,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color text;
  final Color muted;
  final Color border;
  final Color track;

  /// Warning red, e.g. a nearly empty battery.
  final Color low;
  final Color toastBackground;
  final Color toastText;
}

/// Everything a kiln widget needs beyond `context.colors`.
class KilnTokens {
  const KilnTokens({required this.accent, required this.surfaces});

  final KilnAccentTokens accent;
  final KilnSurfaceTokens surfaces;
}
