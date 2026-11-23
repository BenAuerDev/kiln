import 'workflow_preset.dart';
import 'workflow_step.dart';

/// A sequence of steps for the Volcano Hybrid. Presets have a [preset] and
/// an empty [name]; user workflows have a name and no preset.
class Workflow {
  const Workflow({
    required this.id,
    required this.name,
    required this.steps,
    this.heaterOffAtEnd = true,
    this.preset,
  });

  final String id;
  final String name;
  final List<WorkflowStep> steps;

  /// Turns the heater off after the last step.
  final bool heaterOffAtEnd;
  final WorkflowPreset? preset;

  bool get isPreset => preset != null;

  Workflow copyWith({
    String? id,
    String? name,
    List<WorkflowStep>? steps,
    bool? heaterOffAtEnd,
  }) => Workflow(
    id: id ?? this.id,
    name: name ?? this.name,
    steps: steps ?? this.steps,
    heaterOffAtEnd: heaterOffAtEnd ?? this.heaterOffAtEnd,
    preset: preset,
  );

  @override
  bool operator ==(Object other) =>
      other is Workflow &&
      other.id == id &&
      other.name == name &&
      _sameSteps(other.steps, steps) &&
      other.heaterOffAtEnd == heaterOffAtEnd &&
      other.preset == preset;

  static bool _sameSteps(List<WorkflowStep> a, List<WorkflowStep> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, Object.hashAll(steps), heaterOffAtEnd, preset);
}
