/// One step of a Volcano workflow.
sealed class WorkflowStep {
  const WorkflowStep();
}

/// Sets the target and turns the heater on, then waits until the Volcano
/// reaches [celsius].
final class HeatStep extends WorkflowStep {
  const HeatStep(this.celsius);

  final int celsius;

  @override
  bool operator ==(Object other) =>
      other is HeatStep && other.celsius == celsius;

  @override
  int get hashCode => Object.hash(HeatStep, celsius);
}

/// Waits for [duration] with everything left as it is.
final class HoldStep extends WorkflowStep {
  const HoldStep(this.duration);

  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is HoldStep && other.duration == duration;

  @override
  int get hashCode => Object.hash(HoldStep, duration);
}

/// Runs the pump for [duration], then turns it off.
final class AirStep extends WorkflowStep {
  const AirStep(this.duration);

  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is AirStep && other.duration == duration;

  @override
  int get hashCode => Object.hash(AirStep, duration);
}

/// The kinds of step the editor can add.
enum WorkflowStepKind { heat, hold, air }
