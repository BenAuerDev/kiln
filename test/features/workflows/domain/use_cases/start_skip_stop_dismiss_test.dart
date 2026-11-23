import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/use_cases/dismiss_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/skip_workflow_step_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/start_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/stop_workflow_run_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository volcano;
  late Signal<VolcanoStatus?> status;
  late WorkflowRunRepository runs;
  late MockAdvanceWorkflowRunUseCase advance;
  late Signal<String?> activeId;
  late MockConnectionRepository connection;

  final t0 = DateTime(2026, 11, 23, 20);
  const workflow = Workflow(id: 'w', name: 'W', steps: [HeatStep(185)]);

  setUp(() {
    volcano = MockVolcanoRepository();
    status = signal(volcanoStatus(current: 60));
    when(() => volcano.status).thenReturn(status);
    when(() => volcano.setHeater(any())).thenAnswer((_) async => right(unit));
    when(() => volcano.setPump(any())).thenAnswer((_) async => right(unit));
    runs = WorkflowRunRepository();
    activeId = signal('volcano-id');
    connection = MockConnectionRepository();
    when(() => connection.activeDeviceId).thenReturn(activeId);
    advance = MockAdvanceWorkflowRunUseCase();
    when(
      () => advance(skip: any(named: 'skip')),
    ).thenAnswer((_) async => right(unit));
  });

  tearDown(() => runs.clear());

  group('start', () {
    late StartWorkflowRunUseCase start;
    setUp(
      () => start = StartWorkflowRunUseCase(
        runs: runs,
        volcano: volcano,
        connection: connection,
        advance: advance,
        clock: () => t0,
      ),
    );

    test('creates the run at step 1 and advances right away', () async {
      expect(await start(workflow), right<AppError, Unit>(unit));
      final run = runs.run.value!;
      expect(run.workflow, workflow);
      expect(run.stepIndex, 0);
      expect(run.phase, WorkflowRunPhase.running);
      expect(run.stepStartedAt, t0);
      expect(run.stepStartTemperature, 60);
      expect(run.deviceId, 'volcano-id');
      verify(() => advance()).called(1);
    });

    test('needs a connected Volcano', () async {
      status.value = null;
      expect(
        (await start(workflow)).getLeft().toNullable(),
        isA<NotConnectedError>(),
      );
      expect(runs.run.value, isNull);
    });

    test('replacing a pumping run turns the pump off first', () async {
      runs.update(
        WorkflowRun(
          deviceId: 'volcano-id',
          workflow: const Workflow(
            id: 'a',
            name: 'A',
            steps: [AirStep(Duration(minutes: 1))],
          ),
          stepIndex: 0,
          stepStartedAt: t0,
        ),
      );
      await start(workflow);
      verify(() => volcano.setPump(false)).called(1);
      expect(runs.run.value!.workflow, workflow);
    });

    test('a workflow without steps does nothing', () async {
      await start(const Workflow(id: 'e', name: 'E', steps: []));
      expect(runs.run.value, isNull);
      verifyNever(() => advance());
    });
  });

  test('skip advances with skip: true', () async {
    await SkipWorkflowStepUseCase(runs: runs, advance: advance)();
    verify(() => advance(skip: true)).called(1);
  });

  group('stop', () {
    late StopWorkflowRunUseCase stop;
    setUp(() {
      stop = StopWorkflowRunUseCase(runs: runs, volcano: volcano);
      runs.update(
        WorkflowRun(
          deviceId: 'volcano-id',
          workflow: workflow,
          stepIndex: 0,
          stepStartedAt: t0,
        ),
      );
    });

    test('ends the run and turns pump and heater off', () async {
      expect(await stop(), right<AppError, Unit>(unit));
      expect(runs.run.value!.phase, WorkflowRunPhase.stopped);
      verifyInOrder([
        () => volcano.setPump(false),
        () => volcano.setHeater(false),
      ]);
    });

    test('still sends heater off when pump off fails', () async {
      when(
        () => volcano.setPump(false),
      ).thenAnswer((_) async => left(const AppError.timeout()));
      expect((await stop()).getLeft().toNullable(), isA<TimeoutError>());
      verify(() => volcano.setHeater(false)).called(1);
    });

    test('ends the run without a Volcano and says so', () async {
      status.value = null;
      expect((await stop()).getLeft().toNullable(), isA<NotConnectedError>());
      expect(runs.run.value!.phase, WorkflowRunPhase.stopped);
    });

    test('with a device id, stops only a run on that device', () async {
      expect(await stop(deviceId: 'other'), right<AppError, Unit>(unit));
      expect(runs.run.value!.phase, WorkflowRunPhase.running);
      verifyNever(() => volcano.setHeater(any()));
      await stop(deviceId: 'volcano-id');
      expect(runs.run.value!.phase, WorkflowRunPhase.stopped);
      verify(() => volcano.setHeater(false)).called(1);
    });

    test('does nothing when nothing runs', () async {
      runs.clear();
      expect(await stop(), right<AppError, Unit>(unit));
      verifyNever(() => volcano.setHeater(any()));
    });
  });

  test('dismiss forgets an ended run only', () {
    final dismiss = DismissWorkflowRunUseCase(runs: runs);
    final run = WorkflowRun(
      deviceId: 'volcano-id',
      workflow: workflow,
      stepIndex: 0,
      stepStartedAt: t0,
    );
    runs.update(run);
    dismiss();
    expect(runs.run.value, isNotNull);
    runs.end(run.copyWith(phase: WorkflowRunPhase.finished));
    dismiss();
    expect(runs.run.value, isNull);
  });
}
