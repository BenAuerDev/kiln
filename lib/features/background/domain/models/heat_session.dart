import '../../../devices/domain/models/device_model.dart';
import '../../../workflows/domain/models/workflow_run.dart';

/// A device that is heating (or running a workflow) right now: what the
/// background notification is about.
class HeatSession {
  const HeatSession({
    required this.model,
    required this.temperature,
    required this.target,
    required this.ready,
    this.batteryPercent,
    this.boostTarget,
    this.workflow,
  });

  final DeviceModel model;

  /// The Volcano's current temperature, or a portable's setpoint (they do
  /// not report a current temperature), boost included.
  final int temperature;
  final int target;
  final bool ready;
  final int? batteryPercent;

  /// A portable heating at base: where a double-click takes it.
  final int? boostTarget;

  /// The Volcano workflow running on this device.
  final WorkflowRun? workflow;

  @override
  bool operator ==(Object other) =>
      other is HeatSession &&
      other.model == model &&
      other.temperature == temperature &&
      other.target == target &&
      other.ready == ready &&
      other.batteryPercent == batteryPercent &&
      other.boostTarget == boostTarget &&
      other.workflow?.stepIndex == workflow?.stepIndex &&
      other.workflow?.phase == workflow?.phase;

  @override
  int get hashCode => Object.hash(
    model,
    temperature,
    target,
    ready,
    batteryPercent,
    boostTarget,
    workflow?.stepIndex,
    workflow?.phase,
  );
}
