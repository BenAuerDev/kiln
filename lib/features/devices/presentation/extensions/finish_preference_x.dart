import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/finish_preference.dart';
import 'device_finish_x.dart';

extension FinishPreferenceX on FinishPreference {
  String label(AppLocalizations l10n) => switch (this) {
    MatchDevice() => l10n.devicesFinishMatch,
    FixedFinish(:final finish) => finish.label(l10n),
  };
}
