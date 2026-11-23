import '../../../../core/formatters/duration_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/workflow.dart';
import 'workflow_preset_x.dart';

extension WorkflowX on Workflow {
  /// The preset's translated name, or the user's name.
  String displayName(AppLocalizations l10n) => preset?.label(l10n) ?? name;

  /// `6 steps · about 5 min`, with [estimate] from `WorkflowStepService`.
  String summary(AppLocalizations l10n, Duration estimate) =>
      l10n.workflowsSummary(
        l10n.workflowsStepCount(steps.length),
        DurationFormatter.about(estimate, l10n),
      );
}
