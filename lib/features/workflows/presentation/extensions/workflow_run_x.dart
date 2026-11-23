import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/workflow_run.dart';
import 'workflow_step_x.dart';

extension WorkflowRunX on WorkflowRun {
  /// `Step 2 of 6 · Air`, or the phase when the run is not running.
  String headline(AppLocalizations l10n) => switch (phase) {
    WorkflowRunPhase.running => l10n.workflowsStepOf(
      stepIndex + 1,
      workflow.steps.length,
      currentStep?.kind.label(l10n) ?? '',
    ),
    WorkflowRunPhase.paused => l10n.workflowsPaused,
    WorkflowRunPhase.finished => l10n.workflowsFinished,
    WorkflowRunPhase.stopped => l10n.workflowsStopped,
    WorkflowRunPhase.interrupted => l10n.workflowsInterrupted,
  };
}
