import '../models/volcano_heat_phase.dart';
import '../models/volcano_status.dart';
import '../services/volcano_target_rules.dart';

extension VolcanoStatusX on VolcanoStatus {
  /// Within this many °C below the target the Volcano counts as ready.
  static const readyTolerance = 0.5;

  VolcanoHeatPhase get phase {
    if (!heaterOn) return VolcanoHeatPhase.off;
    final current = currentTemperature;
    if (current == null || current < targetTemperature - readyTolerance) {
      return VolcanoHeatPhase.heating;
    }
    return VolcanoHeatPhase.ready;
  }

  /// Position of the current temperature on the 40–230 °C gauge, 0–1.
  double get currentFraction => _fraction(currentTemperature ?? 0);

  /// Position of the target on the 40–230 °C gauge, 0–1.
  double get targetFraction => _fraction(targetTemperature.toDouble());

  static double _fraction(double celsius) =>
      ((celsius - VolcanoTargetRules.minimum) /
              (VolcanoTargetRules.maximum - VolcanoTargetRules.minimum))
          .clamp(0.0, 1.0);
}
