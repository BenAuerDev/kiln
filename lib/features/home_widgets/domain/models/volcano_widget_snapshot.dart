import '../../../devices/domain/models/device_finish.dart';
import '../../../volcano/domain/models/volcano_heat_phase.dart';

/// What the Volcano widget shows while kiln is connected to a real (not
/// demo) Volcano.
class VolcanoWidgetSnapshot {
  const VolcanoWidgetSnapshot({
    required this.temperature,
    required this.target,
    required this.phase,
    required this.pumpOn,
    required this.progress,
    required this.finish,
  });

  /// Current temperature in whole °C, `null` before the first reading.
  final int? temperature;
  final int target;
  final VolcanoHeatPhase phase;
  final bool pumpOn;

  /// Position of [temperature] on the 40–230 °C gauge, 0–1.
  final double progress;
  final DeviceFinish finish;

  bool get heaterOn => phase != VolcanoHeatPhase.off;

  @override
  bool operator ==(Object other) =>
      other is VolcanoWidgetSnapshot &&
      other.temperature == temperature &&
      other.target == target &&
      other.phase == phase &&
      other.pumpOn == pumpOn &&
      other.progress == progress &&
      other.finish == finish;

  @override
  int get hashCode =>
      Object.hash(temperature, target, phase, pumpOn, progress, finish);
}
