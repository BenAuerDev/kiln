import 'workflow.dart';
import 'workflow_step.dart';

enum WorkflowRunPhase {
  running,

  /// The Volcano is not connected; the run continues when it is back.
  paused,
  finished,
  stopped,

  /// Ended by kiln without reaching the Volcano: another device became
  /// active or it was out of reach for too long. It may still be on.
  interrupted,
}

/// State of the workflow that runs or last ran.
class WorkflowRun {
  const WorkflowRun({
    required this.workflow,
    required this.deviceId,
    required this.stepIndex,
    required this.stepStartedAt,
    this.phase = WorkflowRunPhase.running,
    this.stepEntered = false,
    this.stepStartTemperature,
    this.pausedAt,
    this.progress = 0,
    this.elapsed = Duration.zero,
    this.heatStepsReached = 0,
  });

  final Workflow workflow;

  /// The Volcano the run was started on. It never continues on another one.
  final String deviceId;
  final int stepIndex;
  final WorkflowRunPhase phase;

  /// When the run moved to the current step. Timed steps count wall-clock
  /// time from here, pauses included: a Volcano out of reach keeps doing
  /// what it was told.
  final DateTime stepStartedAt;

  /// `false` until the current step's writes succeeded; they are retried on
  /// the next tick, and sent again after a pause.
  final bool stepEntered;

  /// Temperature when the current step started, for a heat step's progress.
  final double? stepStartTemperature;
  final DateTime? pausedAt;

  /// Share of the current step that is done, 0–1, as of the last tick.
  final double progress;

  /// Time spent in the current step, as of the last tick.
  final Duration elapsed;

  /// Heat steps that reached their target (not skipped ones). Goes up by one
  /// each time; the app buzzes on it.
  final int heatStepsReached;

  WorkflowStep? get currentStep =>
      stepIndex < workflow.steps.length ? workflow.steps[stepIndex] : null;

  bool get isActive =>
      phase == WorkflowRunPhase.running || phase == WorkflowRunPhase.paused;

  WorkflowRun copyWith({
    int? stepIndex,
    WorkflowRunPhase? phase,
    DateTime? stepStartedAt,
    bool? stepEntered,
    double? stepStartTemperature,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    double? progress,
    Duration? elapsed,
    int? heatStepsReached,
  }) => WorkflowRun(
    workflow: workflow,
    deviceId: deviceId,
    stepIndex: stepIndex ?? this.stepIndex,
    phase: phase ?? this.phase,
    stepStartedAt: stepStartedAt ?? this.stepStartedAt,
    stepEntered: stepEntered ?? this.stepEntered,
    stepStartTemperature: stepStartTemperature ?? this.stepStartTemperature,
    pausedAt: clearPausedAt ? null : pausedAt ?? this.pausedAt,
    progress: progress ?? this.progress,
    elapsed: elapsed ?? this.elapsed,
    heatStepsReached: heatStepsReached ?? this.heatStepsReached,
  );
}
