import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/services/workflow_editing_service.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/use_cases/find_workflow_use_case.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflow_editor_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockWorkflowsRepository workflows;
  late MockSaveWorkflowUseCase save;
  late MockDeleteWorkflowUseCase delete;
  late MockToastService toast;
  late MockWorkflowsNavigator navigator;

  const mine = Workflow(
    id: 'user.1',
    name: 'Evening',
    steps: [HeatStep(185)],
    heaterOffAtEnd: false,
  );

  setUpAll(() {
    registerFallbackValue(mine);
    registerFallbackValue(ToastLevel.info);
  });

  setUp(() {
    workflows = MockWorkflowsRepository();
    when(() => workflows.byId(any())).thenReturn(null);
    when(() => workflows.byId('user.1')).thenReturn(mine);
    when(() => workflows.workflows).thenReturn(signal(const [mine]));
    save = MockSaveWorkflowUseCase();
    when(() => save(any())).thenAnswer(
      (call) async => right(some(call.positionalArguments.first as Workflow)),
    );
    delete = MockDeleteWorkflowUseCase();
    when(() => delete(any())).thenAnswer((_) async => right(unit));
    toast = MockToastService();
    navigator = MockWorkflowsNavigator();
  });

  Future<WorkflowEditorViewModel> open(String? id) async {
    final load = MockLoadWorkflowsUseCase();
    when(() => load()).thenAnswer((_) async => right(unit));
    final haptics = MockHapticsService();
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    final vm = WorkflowEditorViewModel(
      workflowId: id,
      findWorkflow: FindWorkflowUseCase(repository: workflows),
      editing: WorkflowEditingService(),
      loadWorkflows: load,
      saveWorkflow: save,
      deleteWorkflow: delete,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
    );
    await pumpEventQueue();
    return vm;
  }

  test('a new workflow starts empty and cannot be saved yet', () async {
    final vm = await open(null);
    expect(vm.steps.value, isEmpty);
    expect(vm.isExisting.value, isFalse);
    expect(vm.canSave.value, isFalse);
    vm
      ..setName('Evening')
      ..add(WorkflowStepKind.heat);
    expect(vm.canSave.value, isTrue);
  });

  test('a preset opens as a copy with its name', () async {
    final vm = await open(WorkflowPresets.all.first.id);
    expect(vm.name.value, 'Three-balloon session');
    expect(vm.steps.value, WorkflowPresets.all.first.steps);
    expect(vm.isExisting.value, isFalse);
    await vm.save();
    final saved = verify(() => save(captureAny())).captured.single as Workflow;
    expect(saved.id, '');
    verify(() => navigator.back()).called(1);
  });

  test('a user workflow keeps its id and can be deleted', () async {
    final vm = await open('user.1');
    expect(vm.isExisting.value, isTrue);
    expect(vm.heaterOffAtEnd.value, isFalse);
    expect(vm.draftVersion.value, greaterThan(0));
    await vm.save();
    final saved = verify(() => save(captureAny())).captured.single as Workflow;
    expect(saved.id, 'user.1');
  });

  test('edits go through the editing rules', () async {
    final vm = await open('user.1');
    vm
      ..raise(0)
      ..add(WorkflowStepKind.air)
      ..moveUp(1)
      ..lower(0);
    expect(vm.steps.value, [
      const AirStep(Duration(seconds: 40)),
      const HeatStep(190),
    ]);
    vm.remove(0);
    expect(vm.steps.value, [const HeatStep(190)]);
    vm.setHeaterOffAtEnd(true);
    expect(vm.heaterOffAtEnd.value, isTrue);
  });

  test('delete asks once, then deletes and goes to the list', () async {
    final vm = await open('user.1');
    await vm.delete();
    expect(vm.confirmingDelete.value, isTrue);
    verifyNever(() => delete(any()));
    await vm.delete();
    verify(() => delete('user.1')).called(1);
    verify(() => navigator.goToWorkflows()).called(1);
  });

  test('a failed save shows the error and stays', () async {
    when(
      () => save(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));
    final vm = await open('user.1');
    await vm.save();
    verify(() => toast.show(any(), level: ToastLevel.error)).called(1);
    verifyNever(() => navigator.back());
    expect(vm.saving.value, isFalse);
  });
}
