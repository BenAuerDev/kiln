import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/signal_strength.dart';

extension SignalStrengthX on SignalStrength {
  String label(AppLocalizations l10n) => switch (this) {
    SignalStrength.strong => l10n.devicesSignalStrong,
    SignalStrength.fair => l10n.devicesSignalFair,
    SignalStrength.weak => l10n.devicesSignalWeak,
  };
}
