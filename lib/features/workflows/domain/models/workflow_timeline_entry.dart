import 'workflow_step.dart';

enum WorkflowStepState { done, active, upcoming }

/// One row of the step timeline.
class WorkflowTimelineEntry {
  const WorkflowTimelineEntry({
    required this.number,
    required this.step,
    required this.state,
    required this.isLast,
    this.balloon,
    this.heaterOffAfter = false,
  });

  /// 1-based.
  final int number;
  final WorkflowStep step;
  final WorkflowStepState state;
  final bool isLast;

  /// For air steps: which balloon this fills, counting air steps from 1.
  final int? balloon;

  /// The heater goes off after this step.
  final bool heaterOffAfter;
}
