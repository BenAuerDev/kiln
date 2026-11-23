import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_step_service.dart';
import 'package:kiln/features/workflows/domain/use_cases/advance_workflow_run_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository volcano;
  late Signal<String?> activeId;
  late Signal<VolcanoStatus?> status;
  late WorkflowRunRepository runs;
  late DateTime now;
  late AdvanceWorkflowRunUseCase advance;

  final t0 = DateTime(2026, 11, 23, 20);
  const workflow = Workflow(
    id: 'w',
    name: 'W',
    steps: [HeatStep(185), AirStep(Duration(seconds: 40))],
  );

  void startAt(int index, {bool entered = false, double? startTemp = 23}) =>
      runs.update(
        WorkflowRun(
          deviceId: 'volcano-id',
          workflow: workflow,
          stepIndex: index,
          stepStartedAt: now,
          stepEntered: entered,
          stepStartTemperature: startTemp,
        ),
      );

  WorkflowRun run() => runs.run.value!;

  setUp(() {
    volcano = MockVolcanoRepository();
    status = signal(volcanoStatus());
    when(() => volcano.status).thenReturn(status);
    when(
      () => volcano.setTargetTemperature(any()),
    ).thenAnswer((_) async => right(unit));
    when(() => volcano.setHeater(any())).thenAnswer((_) async => right(unit));
    when(() => volcano.setPump(any())).thenAnswer((_) async => right(unit));
    runs = WorkflowRunRepository();
    now = t0;
    activeId = signal('volcano-id');
    final connection = MockConnectionRepository();
    when(() => connection.activeDeviceId).thenReturn(activeId);
    advance = AdvanceWorkflowRunUseCase(
      runs: runs,
      volcano: volcano,
      connection: connection,
      steps: WorkflowStepService(),
      clock: () => now,
    );
  });

  tearDown(() => runs.clear());

  test('does nothing without an active run', () async {
    expect(await advance(), right<AppError, Unit>(unit));
    verifyZeroInteractions(volcano);
  });

  group('heat step', () {
    test('sets the target and turns the heater on, once', () async {
      startAt(0);
      await advance();
      await advance();
      verify(() => volcano.setTargetTemperature(185)).called(1);
      verify(() => volcano.setHeater(true)).called(1);
      expect(run().stepEntered, isTrue);
    });

    test('turns the heater on even when already at the target', () async {
      status.value = volcanoStatus(current: 185, target: 185);
      startAt(0, startTemp: 185);
      await advance();
      verify(() => volcano.setHeater(true)).called(1);
      expect(run().stepIndex, 1);
    });

    test('skips writes the Volcano does not need', () async {
      status.value = volcanoStatus(target: 185, heaterOn: true);
      startAt(0);
      await advance();
      verifyNever(() => volcano.setTargetTemperature(any()));
      verifyNever(() => volcano.setHeater(any()));
    });

    test('turns a running pump off first', () async {
      status.value = volcanoStatus(pumpOn: true);
      startAt(0);
      await advance();
      verifyInOrder([
        () => volcano.setPump(false),
        () => volcano.setTargetTemperature(185),
      ]);
    });

    test('a failed write is retried on the next tick', () async {
      when(
        () => volcano.setHeater(true),
      ).thenAnswer((_) async => left(const AppError.timeout()));
      startAt(0);
      expect((await advance()).isLeft(), isTrue);
      expect(run().stepEntered, isFalse);
      when(() => volcano.setHeater(true)).thenAnswer((_) async => right(unit));
      await advance();
      expect(run().stepEntered, isTrue);
    });

    test('reports progress, then moves on when reached', () async {
      startAt(0);
      await advance();
      status.value = volcanoStatus(current: 104, heaterOn: true);
      await advance();
      expect(run().progress, closeTo(0.5, 0.01));
      expect(run().stepIndex, 0);

      now = t0.add(const Duration(seconds: 40));
      status.value = volcanoStatus(current: 185, target: 185, heaterOn: true);
      await advance();
      expect(run().stepIndex, 1);
      expect(run().stepEntered, isFalse);
      expect(run().stepStartedAt, now);
      expect(run().stepStartTemperature, 185);
    });
  });

  group('air step', () {
    test('turns the pump on, then off after its time, and finishes', () async {
      status.value = volcanoStatus(current: 185, heaterOn: true);
      startAt(1);
      await advance();
      verify(() => volcano.setPump(true)).called(1);

      now = t0.add(const Duration(seconds: 20));
      await advance();
      expect(run().progress, 0.5);
      expect(run().elapsed, const Duration(seconds: 20));

      now = t0.add(const Duration(seconds: 40));
      await advance();
      verifyInOrder([
        () => volcano.setPump(false),
        () => volcano.setHeater(false),
      ]);
      expect(run().phase, WorkflowRunPhase.finished);
      expect(run().progress, 1);
    });

    test('keeps the heater on at the end when asked to', () async {
      runs.update(
        WorkflowRun(
          deviceId: 'volcano-id',
          workflow: workflow.copyWith(heaterOffAtEnd: false),
          stepIndex: 1,
          stepStartedAt: now,
          stepEntered: true,
        ),
      );
      now = t0.add(const Duration(minutes: 1));
      await advance();
      expect(run().phase, WorkflowRunPhase.finished);
      verifyNever(() => volcano.setHeater(any()));
    });

    test('a failed pump-off keeps the step for the next tick', () async {
      when(
        () => volcano.setPump(false),
      ).thenAnswer((_) async => left(const AppError.timeout()));
      startAt(1, entered: true);
      now = t0.add(const Duration(minutes: 1));
      expect((await advance()).isLeft(), isTrue);
      expect(run().stepIndex, 1);
      expect(run().phase, WorkflowRunPhase.running);
    });
  });

  group('connection', () {
    test('pauses without a Volcano; air time keeps running', () async {
      status.value = volcanoStatus(current: 185, heaterOn: true);
      startAt(1);
      await advance();
      now = t0.add(const Duration(seconds: 10));
      status.value = null;
      await advance();
      expect(run().phase, WorkflowRunPhase.paused);
      expect(run().stepEntered, isFalse);

      // Back after 30 s: the pump is switched on again for the rest.
      now = t0.add(const Duration(seconds: 30));
      status.value = volcanoStatus(current: 185, heaterOn: true);
      await advance();
      expect(run().phase, WorkflowRunPhase.running);
      expect(run().elapsed, const Duration(seconds: 30));
      verify(() => volcano.setPump(true)).called(2);
    });

    test(
      'an air step that ran out while paused is not started again',
      () async {
        status.value = volcanoStatus(current: 185, heaterOn: true);
        startAt(1, entered: true);
        status.value = null;
        await advance();
        now = t0.add(const Duration(seconds: 50));
        status.value = volcanoStatus(
          current: 185,
          heaterOn: true,
          pumpOn: true,
        );
        await advance();
        verifyNever(() => volcano.setPump(true));
        verify(() => volcano.setPump(false)).called(1);
        expect(run().phase, WorkflowRunPhase.finished);
      },
    );

    test('a pause longer than two minutes stops the run', () async {
      startAt(0, entered: true);
      status.value = null;
      await advance();
      now = t0.add(const Duration(minutes: 2, seconds: 1));
      await advance();
      expect(run().phase, WorkflowRunPhase.interrupted);
      status.value = volcanoStatus();
      await advance();
      verifyNever(() => volcano.setHeater(any()));
      verifyNever(() => volcano.setTargetTemperature(any()));
      verifyNever(() => volcano.setPump(any()));
    });

    test('another active device stops the run without writing', () async {
      startAt(0);
      activeId.value = 'venty-id';
      await advance();
      expect(run().phase, WorkflowRunPhase.interrupted);
      verifyNever(() => volcano.setHeater(any()));
      verifyNever(() => volcano.setTargetTemperature(any()));
    });

    test('skip without a Volcano is an error', () async {
      startAt(0);
      status.value = null;
      expect(
        (await advance(skip: true)).getLeft().toNullable(),
        isA<NotConnectedError>(),
      );
    });
  });

  test('skip moves on at once and does not count as reached', () async {
    startAt(0, entered: true);
    await advance(skip: true);
    expect(run().stepIndex, 1);
    expect(run().heatStepsReached, 0);
    verifyNever(() => volcano.setPump(false));
  });

  test('a reached heat step is counted', () async {
    status.value = volcanoStatus(current: 185, target: 185, heaterOn: true);
    startAt(0, entered: true, startTemp: 23);
    await advance();
    expect(run().stepIndex, 1);
    expect(run().heatStepsReached, 1);
  });
}
