import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../volcano/domain/repositories/volcano_repository.dart';
import '../../../volcano/presentation/navigation/volcano_navigator.dart';
import '../../../volcano/presentation/view_models/volcano_session_sync.dart';
import '../../../volcano/presentation/view_models/volcano_tab.dart';
import '../../domain/models/workflow.dart';
import '../../domain/repositories/workflows_repository.dart';
import '../../domain/services/workflow_presets.dart';
import '../../domain/services/workflow_step_service.dart';
import '../../domain/use_cases/load_workflows_use_case.dart';
import '../../domain/use_cases/start_workflow_run_use_case.dart';
import '../extensions/workflow_x.dart';
import '../navigation/workflows_navigator.dart';

/// The Workflows tab: presets and the user's workflows.
class WorkflowsViewModel {
  WorkflowsViewModel({
    WorkflowsRepository? workflows,
    VolcanoRepository? volcano,
    WorkflowStepService? steps,
    LoadWorkflowsUseCase? loadWorkflows,
    StartWorkflowRunUseCase? startRun,
    VolcanoSessionSync? session,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    WorkflowsNavigator? navigator,
    VolcanoNavigator? volcanoNavigator,
  }) : _workflows = workflows ?? sl<WorkflowsRepository>(),
       _volcano = volcano ?? sl<VolcanoRepository>(),
       _steps = steps ?? sl<WorkflowStepService>(),
       _loadWorkflows = loadWorkflows ?? sl<LoadWorkflowsUseCase>(),
       _startRun = startRun ?? sl<StartWorkflowRunUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<WorkflowsNavigator>(),
       _volcanoNavigator = volcanoNavigator ?? sl<VolcanoNavigator>() {
    _session = session ?? VolcanoSessionSync(onError: _showError);
    unawaited(_load());
  }

  final WorkflowsRepository _workflows;
  final VolcanoRepository _volcano;
  final WorkflowStepService _steps;
  final LoadWorkflowsUseCase _loadWorkflows;
  final StartWorkflowRunUseCase _startRun;
  late final VolcanoSessionSync _session;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final WorkflowsNavigator _navigator;
  final VolcanoNavigator _volcanoNavigator;

  final _startingId = signal<String?>(null);

  List<Workflow> get presets => WorkflowPresets.all;

  ReadonlySignal<List<Workflow>> get userWorkflows => _workflows.workflows;

  /// Id of the workflow a start is running for.
  ReadonlySignal<String?> get startingId => _startingId;

  /// Workflows need a connected Volcano to start.
  late final Computed<bool> canStart = computed(
    () => _volcano.status.value != null,
  );

  String summaryOf(Workflow workflow) =>
      workflow.summary(_l10n.strings, _steps.estimate(workflow));

  Future<void> start(Workflow workflow) async {
    if (_startingId.value != null) return;
    unawaited(_haptics.tick());
    _startingId.value = workflow.id;
    final result = await _startRun(workflow);
    _startingId.value = null;
    result.match(_showError, (_) {
      unawaited(_haptics.success());
      _navigator.openRun();
    });
  }

  void edit(Workflow workflow) => _navigator.openEditor(id: workflow.id);

  void create() => _navigator.openEditor();

  void selectTab(VolcanoTab tab) => switch (tab) {
    VolcanoTab.control => _volcanoNavigator.goToControl(),
    VolcanoTab.workflows => null,
    VolcanoTab.devices => _volcanoNavigator.goToDevices(),
  };

  Future<void> _load() async =>
      (await _loadWorkflows()).match(_showError, (_) {});

  void _showError(AppError error) {
    unawaited(_haptics.warning());
    _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
  }

  void dispose() {
    _session.dispose();
    canStart.dispose();
  }
}
