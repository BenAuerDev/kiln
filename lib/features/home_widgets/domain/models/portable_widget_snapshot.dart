import '../../../devices/domain/models/device_finish.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../portable/domain/models/heater_mode.dart';
import '../../../portable/domain/models/portable_heat_phase.dart';
import '../../../portable/domain/models/portable_ladder.dart';

/// What the Venty/Veazy widget shows: the values of a connected, real (not
/// demo) portable.
class PortableWidgetSnapshot {
  const PortableWidgetSnapshot({
    required this.model,
    required this.batteryPercent,
    required this.ladder,
    required this.heaterMode,
    required this.phase,
    required this.activeTemperature,
    required this.finish,
  });

  final DeviceModel model;
  final int batteryPercent;
  final PortableLadder ladder;
  final HeaterMode heaterMode;
  final PortableHeatPhase phase;

  /// What the heater aims for in its current mode, boost included.
  final int activeTemperature;
  final DeviceFinish finish;

  @override
  bool operator ==(Object other) =>
      other is PortableWidgetSnapshot &&
      other.model == model &&
      other.batteryPercent == batteryPercent &&
      other.ladder == ladder &&
      other.heaterMode == heaterMode &&
      other.phase == phase &&
      other.activeTemperature == activeTemperature &&
      other.finish == finish;

  @override
  int get hashCode => Object.hash(
    model,
    batteryPercent,
    ladder,
    heaterMode,
    phase,
    activeTemperature,
    finish,
  );
}
