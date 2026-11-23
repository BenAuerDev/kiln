import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/workflow_preset.dart';

extension WorkflowPresetX on WorkflowPreset {
  String label(AppLocalizations l10n) => switch (this) {
    WorkflowPreset.threeBalloons => l10n.workflowsPresetThreeBalloons,
    WorkflowPreset.singleBalloon => l10n.workflowsPresetSingleBalloon,
    WorkflowPreset.flavourLadder => l10n.workflowsPresetFlavourLadder,
  };
}
