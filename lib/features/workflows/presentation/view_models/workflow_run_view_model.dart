import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../volcano/presentation/view_models/volcano_session_sync.dart';
import '../../domain/models/workflow.dart';
import '../../domain/models/workflow_run.dart';
import '../../domain/models/workflow_timeline_entry.dart';
import '../../domain/repositories/workflow_run_repository.dart';
import '../../domain/services/workflow_step_service.dart';
import '../../domain/use_cases/dismiss_workflow_run_use_case.dart';
import '../../domain/use_cases/find_workflow_use_case.dart';
import '../../domain/use_cases/skip_workflow_step_use_case.dart';
import '../../domain/use_cases/start_workflow_run_use_case.dart';
import '../../domain/use_cases/stop_workflow_run_use_case.dart';
import '../extensions/workflow_x.dart';
import '../navigation/workflows_navigator.dart';

/// The run screen (`Workflow.dc.html`): progress, timeline, Skip and Stop.
class WorkflowRunViewModel {
  WorkflowRunViewModel({
    WorkflowRunRepository? runs,
    WorkflowStepService? steps,
    StartWorkflowRunUseCase? startRun,
    SkipWorkflowStepUseCase? skipStep,
    StopWorkflowRunUseCase? stopRun,
    DismissWorkflowRunUseCase? dismissRun,
    FindWorkflowUseCase? findWorkflow,
    VolcanoSessionSync? session,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    WorkflowsNavigator? navigator,
  }) : _runs = runs ?? sl<WorkflowRunRepository>(),
       _steps = steps ?? sl<WorkflowStepService>(),
       _startRun = startRun ?? sl<StartWorkflowRunUseCase>(),
       _skipStep = skipStep ?? sl<SkipWorkflowStepUseCase>(),
       _stopRun = stopRun ?? sl<StopWorkflowRunUseCase>(),
       _dismissRun = dismissRun ?? sl<DismissWorkflowRunUseCase>(),
       _findWorkflow = findWorkflow ?? sl<FindWorkflowUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<WorkflowsNavigator>() {
    _session = session ?? VolcanoSessionSync(onError: _showError);
  }

  final WorkflowRunRepository _runs;
  final WorkflowStepService _steps;
  final StartWorkflowRunUseCase _startRun;
  final SkipWorkflowStepUseCase _skipStep;
  final StopWorkflowRunUseCase _stopRun;
  final DismissWorkflowRunUseCase _dismissRun;
  final FindWorkflowUseCase _findWorkflow;
  late final VolcanoSessionSync _session;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final WorkflowsNavigator _navigator;

  final _skipping = signal<bool>(false);

  ReadonlySignal<WorkflowRun?> get run => _runs.run;

  /// A skip is under way; another tap is ignored until it is done.
  ReadonlySignal<bool> get skipping => _skipping;

  late final Computed<List<WorkflowTimelineEntry>> timeline = computed(() {
    final run = _runs.run.value;
    return run == null ? const [] : _steps.timeline(run.workflow, run);
  });

  /// An ended run can be run again while its workflow still exists.
  late final Computed<bool> canRunAgain = computed(() {
    final run = _runs.run.value;
    return run != null &&
        !run.isActive &&
        _findWorkflow(run.workflow.id).isSome();
  });

  String summaryOf(Workflow workflow) =>
      workflow.summary(_l10n.strings, _steps.estimate(workflow));

  Future<void> skip() async {
    if (_skipping.value) return;
    _skipping.value = true;
    unawaited(_haptics.tick());
    final result = await _skipStep();
    _skipping.value = false;
    result.match(_showError, (_) {});
  }

  Future<void> stop() async {
    unawaited(_haptics.tick());
    (await _stopRun()).match((_) {
      unawaited(_haptics.warning());
      _toast.show(_l10n.strings.workflowsStopFailed, level: ToastLevel.error);
    }, (_) {});
  }

  /// Runs the latest saved version of the workflow again.
  Future<void> runAgain() async {
    final id = _runs.run.value?.workflow.id;
    final workflow = id == null ? null : _findWorkflow(id).toNullable();
    if (workflow == null) return;
    unawaited(_haptics.tick());
    (await _startRun(workflow)).match(_showError, (_) {});
  }

  void done() {
    _dismissRun();
    _navigator.back();
  }

  void edit() {
    final workflow = _runs.run.value?.workflow;
    if (workflow != null) _navigator.openEditor(id: workflow.id);
  }

  void back() => _navigator.back();

  void _showError(AppError error) {
    unawaited(_haptics.warning());
    _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
  }

  void dispose() {
    _session.dispose();
    timeline.dispose();
    canRunAgain.dispose();
  }
}
