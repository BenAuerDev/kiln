import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../domain/models/workflow_run.dart';
import '../../domain/repositories/workflow_run_repository.dart';
import '../extensions/workflow_run_x.dart';
import '../extensions/workflow_x.dart';
import '../navigation/workflows_navigator.dart';

/// State of the "Running now" banner. Everything lives in repository
/// signals, so each banner may own an instance.
class WorkflowRunBannerViewModel {
  WorkflowRunBannerViewModel({
    WorkflowRunRepository? runs,
    L10nService? l10n,
    WorkflowsNavigator? navigator,
  }) : _runs = runs ?? sl<WorkflowRunRepository>(),
       _l10n = l10n ?? sl<L10nService>(),
       _navigator = navigator ?? sl<WorkflowsNavigator>();

  final WorkflowRunRepository _runs;
  final L10nService _l10n;
  final WorkflowsNavigator _navigator;

  /// The running or paused workflow, `null` otherwise.
  late final Computed<WorkflowRun?> activeRun = computed(() {
    final run = _runs.run.value;
    return run != null && run.isActive ? run : null;
  });

  late final Computed<String> name = computed(
    () => activeRun.value?.workflow.displayName(_l10n.strings) ?? '',
  );

  late final Computed<String> headline = computed(
    () => activeRun.value?.headline(_l10n.strings) ?? '',
  );

  void open() => _navigator.openRun();

  void dispose() {
    activeRun.dispose();
    name.dispose();
    headline.dispose();
  }
}
