import '../../../volcano/domain/services/volcano_target_rules.dart';
import '../models/workflow_step.dart';

/// Pure edits for the workflow editor. Every result is within the limits, so
/// the editor never holds a value the use case would have to fix.
class WorkflowEditingService {
  static const minDuration = Duration(seconds: 5);
  static const maxDuration = Duration(minutes: 10);
  static const durationStep = Duration(seconds: 5);
  static const temperatureStep = 5;
  static const maxSteps = 20;
  static const maxNameLength = 40;

  static const _defaultHeat = 185;
  static const _defaultHold = Duration(seconds: 30);
  static const _defaultAir = Duration(seconds: 45);

  /// Appends a step of [kind]. A new heat step starts 10 °C above the last
  /// one. Does nothing at [maxSteps].
  List<WorkflowStep> add(List<WorkflowStep> steps, WorkflowStepKind kind) {
    if (steps.length >= maxSteps) return steps;
    final step = switch (kind) {
      WorkflowStepKind.heat => HeatStep(_nextHeat(steps)),
      WorkflowStepKind.hold => const HoldStep(_defaultHold),
      WorkflowStepKind.air => const AirStep(_defaultAir),
    };
    return [...steps, step];
  }

  int _nextHeat(List<WorkflowStep> steps) {
    final last = steps.whereType<HeatStep>().lastOrNull;
    return last == null
        ? _defaultHeat
        : VolcanoTargetRules.clamp(last.celsius + 10);
  }

  List<WorkflowStep> remove(List<WorkflowStep> steps, int index) => [
    for (var i = 0; i < steps.length; i++)
      if (i != index) steps[i],
  ];

  /// Moves the step at [index] one place up (`-1`) or down (`1`).
  List<WorkflowStep> move(List<WorkflowStep> steps, int index, int by) {
    final target = index + by;
    if (index < 0 || index >= steps.length) return steps;
    if (target < 0 || target >= steps.length) return steps;
    final result = [...steps];
    final step = result.removeAt(index);
    result.insert(target, step);
    return result;
  }

  /// One −/+ tap on the step at [index]: [temperatureStep] °C for a heat
  /// step, [durationStep] for the others. [direction] is `-1` or `1`.
  List<WorkflowStep> adjust(
    List<WorkflowStep> steps,
    int index,
    int direction,
  ) {
    if (index < 0 || index >= steps.length) return steps;
    final result = [...steps];
    result[index] = switch (steps[index]) {
      HeatStep(:final celsius) => HeatStep(
        VolcanoTargetRules.clamp(celsius + direction * temperatureStep),
      ),
      HoldStep(:final duration) => HoldStep(_adjust(duration, direction)),
      AirStep(:final duration) => AirStep(_adjust(duration, direction)),
    };
    return result;
  }

  Duration _adjust(Duration duration, int direction) =>
      _clampDuration(duration + durationStep * direction);

  Duration _clampDuration(Duration duration) => duration < minDuration
      ? minDuration
      : duration > maxDuration
      ? maxDuration
      : duration;

  /// Brings a step into the limits (for workflows read from storage).
  WorkflowStep normalise(WorkflowStep step) => switch (step) {
    HeatStep(:final celsius) => HeatStep(VolcanoTargetRules.clamp(celsius)),
    HoldStep(:final duration) => HoldStep(_clampDuration(duration)),
    AirStep(:final duration) => AirStep(_clampDuration(duration)),
  };

  /// A workflow can be saved with a name and at least one step.
  bool canSave(String name, List<WorkflowStep> steps) =>
      name.trim().isNotEmpty && steps.isNotEmpty;
}
