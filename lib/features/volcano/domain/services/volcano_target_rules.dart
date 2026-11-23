import 'package:fpdart/fpdart.dart';

/// Target temperature limits of the Volcano Hybrid (official app: 40–230 °C).
abstract final class VolcanoTargetRules {
  static const minimum = 40;
  static const maximum = 230;
  static const presets = [170, 185, 200, 215];

  static int clamp(int celsius) => celsius.clamp(minimum, maximum);

  /// The clamped target to write, or `none()` if it equals [current].
  static Option<int> next({required int current, required int requested}) {
    final clamped = clamp(requested);
    return clamped == current ? const None() : Some(clamped);
  }
}
