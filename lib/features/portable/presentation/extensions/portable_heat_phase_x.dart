import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/portable_heat_phase.dart';

extension PortableHeatPhaseX on PortableHeatPhase {
  String label(AppLocalizations l10n) => switch (this) {
    PortableHeatPhase.off => l10n.portablePhaseOff,
    PortableHeatPhase.heating => l10n.portablePhaseHeating,
    PortableHeatPhase.ready => l10n.portablePhaseReady,
  };
}
