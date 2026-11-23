import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/models/workflow_timeline_entry.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/services/workflow_step_service.dart';

void main() {
  final service = WorkflowStepService();
  final t0 = DateTime(2026, 11, 23, 20);

  WorkflowRun runOf(
    WorkflowStep step, {
    double? start,
    bool entered = true,
    DateTime? pausedAt,
  }) => WorkflowRun(
    deviceId: 'volcano-id',
    workflow: Workflow(id: 'w', name: 'W', steps: [step]),
    stepIndex: 0,
    stepStartedAt: t0,
    stepEntered: entered,
    stepStartTemperature: start,
    pausedAt: pausedAt,
  );

  group('progress', () {
    test('is 0 until the step has been entered', () {
      expect(
        service.progress(
          runOf(const HeatStep(185), start: 20, entered: false),
          currentTemperature: 185,
          now: t0,
        ),
        0,
      );
    });

    test('heat: share of the way from start to target, 1 when reached', () {
      final run = runOf(const HeatStep(180), start: 20);
      expect(
        service.progress(run, currentTemperature: 100, now: t0),
        closeTo(0.5, 0.001),
      );
      expect(service.progress(run, currentTemperature: 179.5, now: t0), 1);
      expect(service.progress(run, currentTemperature: 179, now: t0), 0.99);
      expect(service.progress(run, currentTemperature: null, now: t0), 0);
    });

    test('heat: never reports done before the target', () {
      final run = runOf(const HeatStep(180), start: 20);
      expect(service.progress(run, currentTemperature: 178.5, now: t0), 0.99);
    });

    test('heat: cooling down to a lower target counts too', () {
      final run = runOf(const HeatStep(170), start: 190);
      expect(
        service.progress(run, currentTemperature: 180, now: t0),
        closeTo(0.5, 0.001),
      );
      expect(service.progress(run, currentTemperature: 165, now: t0), 1);
    });

    test('timed steps follow the clock and stop while paused', () {
      final air = runOf(const AirStep(Duration(seconds: 40)));
      expect(
        service.progress(
          air,
          currentTemperature: 185,
          now: t0.add(const Duration(seconds: 10)),
        ),
        0.25,
      );
      expect(
        service.progress(
          air,
          currentTemperature: 185,
          now: t0.add(const Duration(minutes: 5)),
        ),
        1,
      );
      final paused = runOf(
        const HoldStep(Duration(seconds: 40)),
        pausedAt: t0.add(const Duration(seconds: 20)),
      );
      expect(
        service.progress(
          paused,
          currentTemperature: 185,
          now: t0.add(const Duration(minutes: 5)),
        ),
        0.5,
      );
    });
  });

  test('elapsed is never negative', () {
    expect(
      service.elapsed(
        runOf(const HoldStep(Duration(seconds: 5))),
        t0.subtract(const Duration(seconds: 3)),
      ),
      Duration.zero,
    );
  });

  test('estimate: heating at 4 °C/s from 20 °C plus timed steps', () {
    // 175: 38.75 s, +10: 2.5 s, +10: 2.5 s, 3 × 45 s air.
    expect(
      service.estimate(WorkflowPresets.all.first),
      const Duration(seconds: 179),
    );
    expect(
      service.estimate(
        const Workflow(
          id: 'down',
          name: 'Down',
          steps: [HeatStep(200), HeatStep(180)],
        ),
      ),
      const Duration(seconds: 45),
    );
  });

  group('timeline', () {
    final workflow = WorkflowPresets.all.first;

    test('without a run every step is upcoming; balloons count air steps', () {
      final entries = service.timeline(workflow, null);
      expect(entries.map((e) => e.state).toSet(), {WorkflowStepState.upcoming});
      expect(entries.map((e) => e.balloon), [null, 1, null, 2, null, 3]);
      expect(entries.map((e) => e.number), [1, 2, 3, 4, 5, 6]);
      expect(entries.last.isLast, isTrue);
      expect(entries.last.heaterOffAfter, isTrue);
      expect(entries.first.heaterOffAfter, isFalse);
    });

    test('done before the current step, active on it', () {
      final run = WorkflowRun(
        deviceId: 'volcano-id',
        workflow: workflow,
        stepIndex: 1,
        stepStartedAt: t0,
      );
      expect(service.timeline(workflow, run).map((e) => e.state).take(3), [
        WorkflowStepState.done,
        WorkflowStepState.active,
        WorkflowStepState.upcoming,
      ]);
    });

    test('a finished run shows every step done', () {
      final run = WorkflowRun(
        deviceId: 'volcano-id',
        workflow: workflow,
        stepIndex: 5,
        stepStartedAt: t0,
        phase: WorkflowRunPhase.finished,
      );
      expect(service.timeline(workflow, run).map((e) => e.state).toSet(), {
        WorkflowStepState.done,
      });
    });

    test('no heater-off note when the workflow keeps heating', () {
      final entries = service.timeline(
        workflow.copyWith(heaterOffAtEnd: false),
        null,
      );
      expect(entries.last.heaterOffAfter, isFalse);
    });
  });

  group('reachedMilestone', () {
    final before = WorkflowRun(
      deviceId: 'volcano-id',
      workflow: WorkflowPresets.all.first,
      stepIndex: 0,
      stepStartedAt: t0,
    );

    test('a reached heat step and a finish count', () {
      expect(
        service.reachedMilestone(before, before.copyWith(heatStepsReached: 1)),
        isTrue,
      );
      expect(
        service.reachedMilestone(
          before,
          before.copyWith(phase: WorkflowRunPhase.finished),
        ),
        isTrue,
      );
    });

    test('a skip, a stop, another run or no run do not', () {
      expect(
        service.reachedMilestone(before, before.copyWith(stepIndex: 1)),
        isFalse,
      );
      expect(
        service.reachedMilestone(
          before,
          before.copyWith(phase: WorkflowRunPhase.stopped),
        ),
        isFalse,
      );
      final other = WorkflowRun(
        deviceId: 'volcano-id',
        workflow: WorkflowPresets.all.last,
        stepIndex: 0,
        stepStartedAt: t0,
        heatStepsReached: 3,
      );
      expect(service.reachedMilestone(before, other), isFalse);
      expect(service.reachedMilestone(null, before), isFalse);
      expect(service.reachedMilestone(before, null), isFalse);
    });
  });
}
