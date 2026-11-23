import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/services/workflow_step_service.dart';
import 'package:kiln/features/workflows/domain/use_cases/find_workflow_use_case.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflow_run_view_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late WorkflowRunRepository runs;
  late MockStartWorkflowRunUseCase startRun;
  late MockSkipWorkflowStepUseCase skip;
  late MockStopWorkflowRunUseCase stop;
  late MockDismissWorkflowRunUseCase dismiss;
  late MockHapticsService haptics;
  late MockToastService toast;
  late MockWorkflowsNavigator navigator;
  late MockWorkflowsRepository workflows;
  late WorkflowRunViewModel vm;

  final workflow = WorkflowPresets.all.first;
  final run = WorkflowRun(
    deviceId: 'volcano-id',
    workflow: workflow,
    stepIndex: 0,
    stepStartedAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(workflow);
    registerFallbackValue(ToastLevel.info);
  });

  setUp(() {
    runs = WorkflowRunRepository()..update(run);
    startRun = MockStartWorkflowRunUseCase();
    skip = MockSkipWorkflowStepUseCase();
    stop = MockStopWorkflowRunUseCase();
    dismiss = MockDismissWorkflowRunUseCase();
    when(() => startRun(any())).thenAnswer((_) async => right(unit));
    when(() => skip()).thenAnswer((_) async => right(unit));
    when(() => stop()).thenAnswer((_) async => right(unit));
    haptics = MockHapticsService();
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    toast = MockToastService();
    navigator = MockWorkflowsNavigator();
    workflows = MockWorkflowsRepository();
    when(() => workflows.byId(any())).thenReturn(null);
    vm = WorkflowRunViewModel(
      runs: runs,
      steps: WorkflowStepService(),
      startRun: startRun,
      skipStep: skip,
      stopRun: stop,
      dismissRun: dismiss,
      findWorkflow: FindWorkflowUseCase(repository: workflows),
      session: MockVolcanoSessionSync(),
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
    );
  });

  tearDown(() {
    vm.dispose();
    runs.clear();
  });

  test('timeline follows the run', () {
    expect(vm.timeline.value, hasLength(6));
    runs.clear();
    expect(vm.timeline.value, isEmpty);
  });

  test('run again needs an ended run whose workflow still exists', () {
    expect(vm.canRunAgain.value, isFalse);
    runs.end(run.copyWith(phase: WorkflowRunPhase.finished));
    expect(vm.canRunAgain.value, isTrue);
    when(() => workflows.byId(any())).thenReturn(null);
    runs.end(
      WorkflowRun(
        deviceId: 'volcano-id',
        workflow: const Workflow(id: 'user.gone', name: 'G', steps: []),
        stepIndex: 0,
        stepStartedAt: DateTime(2026),
        phase: WorkflowRunPhase.stopped,
      ),
    );
    expect(vm.canRunAgain.value, isFalse);
  });

  test('a second skip while one is under way is ignored', () async {
    final pending = Completer<Either<AppError, Unit>>();
    when(() => skip()).thenAnswer((_) => pending.future);
    final first = vm.skip();
    expect(vm.skipping.value, isTrue);
    await vm.skip();
    pending.complete(right(unit));
    await first;
    expect(vm.skipping.value, isFalse);
    verify(() => skip()).called(1);
  });

  test('skip and stop go to the use cases', () async {
    await vm.skip();
    await vm.stop();
    verify(() => skip()).called(1);
    verify(() => stop()).called(1);
    verifyNever(() => toast.show(any(), level: any(named: 'level')));
  });

  test(
    'a stop that cannot reach the Volcano warns that it may still heat',
    () async {
      when(
        () => stop(),
      ).thenAnswer((_) async => left(const AppError.notConnected()));
      await vm.stop();
      verify(
        () => toast.show(
          'Stopped. kiln couldn\'t reach the Volcano, so it may still be heating.',
          level: ToastLevel.error,
        ),
      ).called(1);
    },
  );

  test('run again starts the latest saved version', () async {
    const edited = Workflow(id: 'user.1', name: 'New', steps: [HeatStep(200)]);
    when(() => workflows.byId('user.1')).thenReturn(edited);
    runs.end(
      WorkflowRun(
        deviceId: 'volcano-id',
        workflow: const Workflow(
          id: 'user.1',
          name: 'Old',
          steps: [HeatStep(180)],
        ),
        stepIndex: 0,
        stepStartedAt: DateTime(2026),
        phase: WorkflowRunPhase.finished,
      ),
    );
    await vm.runAgain();
    verify(() => startRun(edited)).called(1);
  });

  test('run again, done, edit and back', () async {
    await vm.runAgain();
    verify(() => startRun(workflow)).called(1);
    vm
      ..done()
      ..edit()
      ..back();
    verify(() => dismiss()).called(1);
    verify(() => navigator.back()).called(2);
    verify(() => navigator.openEditor(id: workflow.id)).called(1);
  });
}
