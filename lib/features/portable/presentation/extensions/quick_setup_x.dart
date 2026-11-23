import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/quick_setup.dart';

extension QuickSetupX on QuickSetup {
  String label(AppLocalizations l10n) => switch (this) {
    QuickSetup.flavour => l10n.portableQuickSetupFlavour,
    QuickSetup.balanced => l10n.portableQuickSetupBalanced,
    QuickSetup.full => l10n.portableQuickSetupFull,
  };
}
