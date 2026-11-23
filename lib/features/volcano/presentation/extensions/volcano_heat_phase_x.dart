import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/volcano_heat_phase.dart';

extension VolcanoHeatPhaseX on VolcanoHeatPhase {
  String label(AppLocalizations l10n) => switch (this) {
    VolcanoHeatPhase.off => l10n.volcanoPhaseOff,
    VolcanoHeatPhase.heating => l10n.volcanoPhaseHeating,
    VolcanoHeatPhase.ready => l10n.volcanoPhaseReady,
  };
}
