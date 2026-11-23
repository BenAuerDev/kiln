import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_tab.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/services/workflow_step_service.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflows_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockWorkflowsRepository workflows;
  late WorkflowRunRepository runs;
  late MockVolcanoRepository volcano;
  late Signal<VolcanoStatus?> status;
  late MockStartWorkflowRunUseCase startRun;
  late MockToastService toast;
  late MockWorkflowsNavigator navigator;
  late MockVolcanoNavigator volcanoNavigator;
  late WorkflowsViewModel vm;

  final preset = WorkflowPresets.all.first;

  setUpAll(() {
    registerFallbackValue(preset);
    registerFallbackValue(ToastLevel.info);
  });

  setUp(() {
    workflows = MockWorkflowsRepository();
    when(() => workflows.workflows).thenReturn(signal(const <Workflow>[]));
    runs = WorkflowRunRepository();
    volcano = MockVolcanoRepository();
    status = signal(volcanoStatus());
    when(() => volcano.status).thenReturn(status);
    startRun = MockStartWorkflowRunUseCase();
    when(() => startRun(any())).thenAnswer((_) async => right(unit));
    final load = MockLoadWorkflowsUseCase();
    when(() => load()).thenAnswer((_) async => right(unit));
    final haptics = MockHapticsService();
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    toast = MockToastService();
    navigator = MockWorkflowsNavigator();
    volcanoNavigator = MockVolcanoNavigator();
    vm = WorkflowsViewModel(
      workflows: workflows,
      volcano: volcano,
      steps: WorkflowStepService(),
      loadWorkflows: load,
      startRun: startRun,
      session: MockVolcanoSessionSync(),
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
      volcanoNavigator: volcanoNavigator,
    );
  });

  tearDown(() => runs.clear());

  test('summarises presets in the app language', () {
    expect(vm.summaryOf(preset), '6 steps · about 3 min');
  });

  test('start opens the run screen', () async {
    await vm.start(preset);
    verify(() => startRun(preset)).called(1);
    verify(() => navigator.openRun()).called(1);
    expect(vm.startingId.value, isNull);
  });

  test('a failed start shows a toast and stays', () async {
    when(
      () => startRun(any()),
    ).thenAnswer((_) async => left(const AppError.notConnected()));
    await vm.start(preset);
    verify(() => toast.show(any(), level: ToastLevel.error)).called(1);
    verifyNever(() => navigator.openRun());
  });

  test('canStart needs a connected Volcano', () {
    expect(vm.canStart.value, isTrue);
    status.value = null;
    expect(vm.canStart.value, isFalse);
  });

  test('navigation', () {
    vm
      ..edit(preset)
      ..create()
      ..selectTab(VolcanoTab.control)
      ..selectTab(VolcanoTab.devices)
      ..selectTab(VolcanoTab.workflows);
    verify(() => navigator.openEditor(id: preset.id)).called(1);
    verify(() => navigator.openEditor()).called(1);
    verify(() => volcanoNavigator.goToControl()).called(1);
    verify(() => volcanoNavigator.goToDevices()).called(1);
  });
}
