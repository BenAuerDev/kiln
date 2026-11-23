import 'dart:math' as math;

import '../../../volcano/domain/extensions/volcano_status_x.dart';
import '../models/workflow.dart';
import '../models/workflow_run.dart';
import '../models/workflow_step.dart';
import '../models/workflow_timeline_entry.dart';

/// Pure rules of a workflow run: step progress, the time estimate and the
/// timeline rows.
class WorkflowStepService {
  /// A heat step is done within this many degrees of its target: the
  /// Control screen's "ready" rule. Near the target the Volcano reports
  /// whole degrees (seen on hardware), so this means "at target".
  static const reachedTolerance = VolcanoStatusX.readyTolerance;

  /// Rough heating rate for the estimate.
  static const heatPerSecond = 4.0;

  /// Room temperature assumed before the first heat step.
  static const startTemperature = 20.0;

  /// Time spent in the current step: stops counting while paused.
  Duration elapsed(WorkflowRun run, DateTime now) {
    final end = run.pausedAt ?? now;
    final elapsed = end.difference(run.stepStartedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Share of the current step that is done, 0–1. Only a finished step
  /// reports 1.
  double progress(
    WorkflowRun run, {
    required double? currentTemperature,
    required DateTime now,
  }) {
    if (!run.stepEntered) return 0;
    return switch (run.currentStep) {
      null => 1,
      HeatStep(:final celsius) => _heatProgress(
        celsius,
        start: run.stepStartTemperature ?? currentTemperature,
        current: currentTemperature,
      ),
      HoldStep(:final duration) ||
      AirStep(:final duration) => _timeProgress(elapsed(run, now), duration),
    };
  }

  double _heatProgress(int celsius, {double? start, double? current}) {
    if (current == null) return 0;
    if ((current - celsius).abs() <= reachedTolerance) return 1;
    final from = start ?? current;
    final span = celsius - from;
    if (span.abs() <= reachedTolerance) return 0;
    final share = (current - from) / span;
    // Overshooting the target (e.g. cooling past it) also counts as reached.
    if (share >= 1) return 1;
    return share.clamp(0.0, 0.99);
  }

  double _timeProgress(Duration elapsed, Duration duration) {
    if (duration <= Duration.zero) return 1;
    return (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// About how long [workflow] takes from room temperature: timed steps plus
  /// heating at [heatPerSecond]. Cooling down to a lower target is not
  /// counted.
  Duration estimate(Workflow workflow) {
    var seconds = 0.0;
    var temperature = startTemperature;
    for (final step in workflow.steps) {
      switch (step) {
        case HeatStep(:final celsius):
          seconds += math.max(0, celsius - temperature) / heatPerSecond;
          temperature = celsius.toDouble();
        case HoldStep(:final duration) || AirStep(:final duration):
          seconds += duration.inSeconds;
      }
    }
    return Duration(seconds: seconds.round());
  }

  /// Whether going from [before] to [after] is worth a "buzz": a heat step of
  /// the same run reached its target, or the run finished.
  bool reachedMilestone(WorkflowRun? before, WorkflowRun? after) {
    if (before == null || after == null) return false;
    if (before.workflow.id != after.workflow.id ||
        before.deviceId != after.deviceId) {
      return false;
    }
    final finished =
        after.phase == WorkflowRunPhase.finished &&
        before.phase != WorkflowRunPhase.finished;
    return finished || after.heatStepsReached > before.heatStepsReached;
  }

  /// One row per step. Without a run (or for another workflow) every step is
  /// upcoming; a finished run shows every step done.
  List<WorkflowTimelineEntry> timeline(Workflow workflow, WorkflowRun? run) {
    final steps = workflow.steps;
    final current = run != null && run.workflow.id == workflow.id ? run : null;
    var balloons = 0;
    return [
      for (var i = 0; i < steps.length; i++)
        WorkflowTimelineEntry(
          number: i + 1,
          step: steps[i],
          state: _state(i, current),
          isLast: i == steps.length - 1,
          balloon: steps[i] is AirStep ? ++balloons : null,
          heaterOffAfter: i == steps.length - 1 && workflow.heaterOffAtEnd,
        ),
    ];
  }

  WorkflowStepState _state(int index, WorkflowRun? run) {
    if (run == null) return WorkflowStepState.upcoming;
    if (run.phase == WorkflowRunPhase.finished) return WorkflowStepState.done;
    if (index < run.stepIndex) return WorkflowStepState.done;
    if (index == run.stepIndex && run.isActive) return WorkflowStepState.active;
    return WorkflowStepState.upcoming;
  }
}
