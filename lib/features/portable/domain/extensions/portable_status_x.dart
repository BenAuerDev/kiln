import '../models/heater_mode.dart';
import '../models/portable_battery.dart';
import '../models/portable_heat_phase.dart';
import '../models/portable_status.dart';
import '../services/portable_temperature_limits.dart';

extension PortableStatusX on PortableStatus {
  PortableHeatPhase get heatPhase {
    if (heaterMode == HeaterMode.off) return PortableHeatPhase.off;
    return setpointReached
        ? PortableHeatPhase.ready
        : PortableHeatPhase.heating;
  }

  bool get boostActive =>
      heaterMode == HeaterMode.boost || heaterMode == HeaterMode.superboost;

  /// Degrees above base in superboost: boost and superboost stack.
  int get superBoostTotal => boostOffset + superBoostOffset;

  PortableBattery get battery =>
      PortableBattery(percent: batteryPercent, charging: charging);

  /// Position of the current temperature on the 40–210 °C gauge, 0–1, or
  /// `null` while the device reports no reading.
  double? get currentPosition {
    final current = currentTemperature;
    if (current == null) return null;
    const min = PortableTemperatureLimits.minTemperature;
    const max = PortableTemperatureLimits.maxTemperature;
    return ((current - min) / (max - min)).clamp(0.0, 1.0);
  }

  /// Gauge arc length. Without a live reading the arc is full up to
  /// [targetPosition] once the device reports ready, and empty before that.
  double gaugeProgress(double targetPosition) =>
      currentPosition ??
      (heatPhase == PortableHeatPhase.ready ? targetPosition : 0);
}
