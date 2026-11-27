import 'package:flutter/painting.dart';

import 'kiln_tokens.dart';

/// The only place in the app that contains colour literals.
abstract final class KilnPalette {
  static const ember = KilnFinishTokens(
    dark: KilnAccentTokens(
      accent: Color(0xFFFF7A1A),
      accentText: Color(0xFFFF8A33),
      onAccent: Color(0xFF111111),
      gradientStart: Color(0xFFFFC285),
      gradientEnd: Color(0xFFFF6A00),
      glow: Color(0x73FF7A1A),
    ),
    light: KilnAccentTokens(
      accent: Color(0xFFFF7A1A),
      accentText: Color(0xFFC2410C),
      onAccent: Color(0xFF111111),
      gradientStart: Color(0xFFFFC285),
      gradientEnd: Color(0xFFFF6A00),
      glow: Color(0x73FF7A1A),
    ),
  );

  static const lava = KilnFinishTokens(
    dark: KilnAccentTokens(
      accent: Color(0xFFFF4D2E),
      accentText: Color(0xFFFF6B4D),
      onAccent: Color(0xFF111111),
      gradientStart: Color(0xFFFFB199),
      gradientEnd: Color(0xFFE5361B),
      glow: Color(0x73FF4D2E),
    ),
    light: KilnAccentTokens(
      accent: Color(0xFFFF4D2E),
      accentText: Color(0xFFB42318),
      onAccent: Color(0xFF111111),
      gradientStart: Color(0xFFFFB199),
      gradientEnd: Color(0xFFE5361B),
      glow: Color(0x73FF4D2E),
    ),
  );

  static const blue = KilnFinishTokens(
    dark: KilnAccentTokens(
      accent: Color(0xFF3D8BFF),
      accentText: Color(0xFF6AA6FF),
      onAccent: Color(0xFF0B0B0C),
      gradientStart: Color(0xFF9CC4FF),
      gradientEnd: Color(0xFF2F6BFF),
      glow: Color(0x733D8BFF),
    ),
    light: KilnAccentTokens(
      accent: Color(0xFF3D8BFF),
      accentText: Color(0xFF1D4ED8),
      onAccent: Color(0xFF0B0B0C),
      gradientStart: Color(0xFF9CC4FF),
      gradientEnd: Color(0xFF2F6BFF),
      glow: Color(0x733D8BFF),
    ),
  );

  static const pink = KilnFinishTokens(
    dark: KilnAccentTokens(
      accent: Color(0xFFFF5FA2),
      accentText: Color(0xFFFF7EB6),
      onAccent: Color(0xFF111111),
      gradientStart: Color(0xFFFFB3D3),
      gradientEnd: Color(0xFFFF3D8B),
      glow: Color(0x66FF5FA2),
    ),
    light: KilnAccentTokens(
      accent: Color(0xFFFF5FA2),
      accentText: Color(0xFFBE185D),
      onAccent: Color(0xFF111111),
      gradientStart: Color(0xFFFFB3D3),
      gradientEnd: Color(0xFFFF3D8B),
      glow: Color(0x66FF5FA2),
    ),
  );

  static const mono = KilnFinishTokens(
    dark: KilnAccentTokens(
      accent: Color(0xFFF9FAFB),
      accentText: Color(0xFFF9FAFB),
      onAccent: Color(0xFF111111),
      gradientStart: Color(0xFF4B5563),
      gradientEnd: Color(0xFFFFFFFF),
      glow: Color(0x40FFFFFF),
    ),
    light: KilnAccentTokens(
      accent: Color(0xFF121212),
      accentText: Color(0xFF121212),
      onAccent: Color(0xFFF7F7F5),
      gradientStart: Color(0xFFC4C4BF),
      gradientEnd: Color(0xFF121212),
      glow: Color(0x2E000000),
    ),
  );

  static const darkSurfaces = KilnSurfaceTokens(
    background: Color(0xFF0A0A0F),
    surface: Color(0xFF111118),
    surfaceRaised: Color(0xFF1C1C26),
    text: Color(0xFFF9FAFB),
    muted: Color(0xFF9CA3AF),
    border: Color(0xFF1F2937),
    track: Color(0xFF1F2937),
    low: Color(0xFFF87171),
    toastBackground: Color(0xFFF9FAFB),
    toastText: Color(0xFF111827),
  );

  static const lightSurfaces = KilnSurfaceTokens(
    background: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF3F4F6),
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF5A5A5A),
    border: Color(0xFFE5E7EB),
    track: Color(0xFFE5E7EB),
    low: Color(0xFFDC2626),
    toastBackground: Color(0xFF111827),
    toastText: Color(0xFFF9FAFB),
  );
}
