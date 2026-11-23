import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/workflow_timeline_entry.dart';

extension WorkflowStepStateX on WorkflowStepState {
  /// "Done", "Now" or empty, at the end of a timeline row.
  String tag(AppLocalizations l10n) => switch (this) {
    WorkflowStepState.done => l10n.workflowsTagDone,
    WorkflowStepState.active => l10n.workflowsTagNow,
    WorkflowStepState.upcoming => '',
  };
}
