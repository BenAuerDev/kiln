import 'package:fpdart/fpdart.dart';

/// Single source of truth for the Venty/Veazy temperature ranges in kiln.
abstract final class PortableTemperatureLimits {
  static const minTemperature = 40;
  static const maxTemperature = 210;

  /// Boost and superboost offsets (design: `Veazy.dc.html`).
  static const minOffset = 1;
  static const maxOffset = 30;

  static int clampTemperature(int celsius) =>
      celsius.clamp(minTemperature, maxTemperature);

  static int clampOffset(int offset) => offset.clamp(minOffset, maxOffset);

  /// `current + delta`, clamped to `min…max`. Returns `none()` when the value
  /// would not move in the direction of [delta] (zero delta, already at the
  /// limit, or a device value outside the range that clamping would move the
  /// wrong way).
  static Option<int> step(
    int current,
    int delta, {
    required int min,
    required int max,
  }) {
    final next = (current + delta).clamp(min, max);
    if (delta == 0 || (next - current).sign != delta.sign) return none();
    return some(next);
  }
}
