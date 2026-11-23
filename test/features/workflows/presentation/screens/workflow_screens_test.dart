import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_editing_service.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/services/workflow_step_service.dart';
import 'package:kiln/features/workflows/domain/use_cases/find_workflow_use_case.dart';
import 'package:kiln/features/workflows/presentation/screens/workflow_editor_screen.dart';
import 'package:kiln/features/workflows/presentation/screens/workflow_run_screen.dart';
import 'package:kiln/features/workflows/presentation/screens/workflows_screen.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflow_editor_view_model.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflow_run_view_model.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflows_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../devices/helpers/demo_badge_stub.dart';
import '../../../portable/presentation/pump_app.dart';
import '../../helpers/run_banner_registration.dart';
import '../../mocks.dart';

void main() {
  late WorkflowRunRepository runs;
  late MockWorkflowsRepository workflows;
  late MockHapticsService haptics;
  late MockStartWorkflowRunUseCase startRun;
  late MockWorkflowsNavigator navigator;

  final preset = WorkflowPresets.all.first;

  setUpAll(() {
    registerFallbackValue(preset);
    registerFallbackValue(ToastLevel.info);
  });

  setUp(() {
    registerDemoBadge();
    registerRunBanner();
    runs = WorkflowRunRepository();
    workflows = MockWorkflowsRepository();
    when(() => workflows.workflows).thenReturn(
      signal(const [
        Workflow(id: 'user.1', name: 'Evening', steps: [HeatStep(190)]),
      ]),
    );
    when(() => workflows.byId(any())).thenReturn(null);
    haptics = MockHapticsService();
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    startRun = MockStartWorkflowRunUseCase();
    when(() => startRun(any())).thenAnswer((_) async => right(unit));
    navigator = MockWorkflowsNavigator();
    final load = MockLoadWorkflowsUseCase();
    when(() => load()).thenAnswer((_) async => right(unit));
    final volcano = MockVolcanoRepository();
    when(() => volcano.status).thenReturn(signal(volcanoStatus()));
    final session = MockVolcanoSessionSync();
    sl
      ..registerFactory(
        () => WorkflowsViewModel(
          workflows: workflows,
          volcano: volcano,
          steps: WorkflowStepService(),
          loadWorkflows: load,
          startRun: startRun,
          session: session,
          l10n: FakeL10nService(),
          haptics: haptics,
          toast: MockToastService(),
          navigator: navigator,
          volcanoNavigator: MockVolcanoNavigator(),
        ),
      )
      ..registerFactory(
        () => WorkflowRunViewModel(
          runs: runs,
          steps: WorkflowStepService(),
          startRun: startRun,
          skipStep: MockSkipWorkflowStepUseCase(),
          stopRun: MockStopWorkflowRunUseCase(),
          dismissRun: MockDismissWorkflowRunUseCase(),
          findWorkflow: FindWorkflowUseCase(repository: workflows),
          session: session,
          l10n: FakeL10nService(),
          haptics: haptics,
          toast: MockToastService(),
          navigator: navigator,
        ),
      )
      ..registerFactoryParam<WorkflowEditorViewModel, String?, void>(
        (id, _) => WorkflowEditorViewModel(
          workflowId: id,
          findWorkflow: FindWorkflowUseCase(repository: workflows),
          editing: WorkflowEditingService(),
          loadWorkflows: load,
          saveWorkflow: MockSaveWorkflowUseCase(),
          deleteWorkflow: MockDeleteWorkflowUseCase(),
          l10n: FakeL10nService(),
          haptics: haptics,
          toast: MockToastService(),
          navigator: navigator,
        ),
      );
  });

  tearDown(() async {
    runs.clear();
    await sl.reset();
  });

  testWidgets('list shows presets and own workflows; Start starts', (
    tester,
  ) async {
    await pumpKiln(tester, const WorkflowsScreen());
    expect(find.text('Three-balloon session'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('New workflow'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Start Three-balloon session'));
    await tester.pump();
    verify(() => startRun(preset)).called(1);
  });

  testWidgets('run screen shows the step, the timeline and Skip / Stop', (
    tester,
  ) async {
    runs.update(
      WorkflowRun(
        deviceId: 'volcano-id',
        workflow: preset,
        stepIndex: 1,
        stepStartedAt: DateTime(2026),
        progress: 0.4,
        elapsed: const Duration(seconds: 18),
      ),
    );
    await pumpKiln(tester, const WorkflowRunScreen());
    expect(find.text('STEP 2 OF 6 · AIR'), findsOneWidget);
    expect(find.text('0:18'), findsOneWidget);
    expect(find.text('Heat to 175 °C'), findsOneWidget);
    expect(find.text('Fill balloon 3, heater off after'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Skip step'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('editor copies a preset and adds steps', (tester) async {
    await pumpKiln(tester, WorkflowEditorScreen(workflowId: preset.id));
    await tester.pump();
    expect(find.text('New workflow'), findsOneWidget);
    expect(find.text('Air 45 s'), findsNWidgets(3));

    await tester.tap(find.bySemanticsLabel('Add a Hold step'));
    await tester.pump();
    expect(find.text('Hold 30 s'), findsOneWidget);
  });
}
