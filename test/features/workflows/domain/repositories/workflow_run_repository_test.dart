import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';

void main() {
  final run = WorkflowRun(
    deviceId: 'volcano-id',
    workflow: const Workflow(id: 'w', name: 'W', steps: [HeatStep(185)]),
    stepIndex: 0,
    stepStartedAt: DateTime(2026),
  );

  test('ticks until end, and keeps the ended run', () {
    fakeAsync((async) {
      final repository = WorkflowRunRepository();
      var ticks = 0;
      repository.start(run, () async => ticks++);
      async.elapse(const Duration(seconds: 2));
      expect(ticks, 4);
      repository.end(run.copyWith(phase: WorkflowRunPhase.finished));
      async.elapse(const Duration(seconds: 2));
      expect(ticks, 4);
      expect(repository.run.value!.phase, WorkflowRunPhase.finished);
      repository.clear();
      expect(repository.run.value, isNull);
    });
  });

  test('skips a tick while the previous one is still running', () {
    fakeAsync((async) {
      final repository = WorkflowRunRepository();
      final slow = Completer<void>();
      var ticks = 0;
      repository.start(run, () {
        ticks++;
        return slow.future;
      });
      async.elapse(const Duration(seconds: 2));
      expect(ticks, 1);
      slow.complete();
      async.elapse(const Duration(milliseconds: 500));
      expect(ticks, 2);
      repository.clear();
    });
  });

  test('a new start replaces the old ticker', () {
    fakeAsync((async) {
      final repository = WorkflowRunRepository();
      var first = 0;
      var second = 0;
      repository
        ..start(run, () async => first++)
        ..start(run, () async => second++);
      async.elapse(const Duration(seconds: 1));
      expect(first, 0);
      expect(second, 2);
      repository.clear();
    });
  });
}
