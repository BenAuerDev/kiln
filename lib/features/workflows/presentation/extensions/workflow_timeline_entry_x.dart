import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/workflow_step.dart';
import '../../domain/models/workflow_timeline_entry.dart';

extension WorkflowTimelineEntryX on WorkflowTimelineEntry {
  /// `Wait until ready, then buzz`, `Fill balloon 2`, and for the last
  /// step `…, heater off after` when the workflow ends with the heater off.
  String subtitle(AppLocalizations l10n) {
    final base = switch (step) {
      HeatStep() => l10n.workflowsHeatSubtitle,
      HoldStep() => l10n.workflowsHoldSubtitle,
      AirStep() => l10n.workflowsAirSubtitle(balloon ?? number),
    };
    return heaterOffAfter ? l10n.workflowsThenHeaterOff(base) : base;
  }
}
