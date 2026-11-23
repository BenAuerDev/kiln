import '../../../../core/formatters/duration_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/ramp_profile.dart';

extension RampProfileX on RampProfile {
  String name(AppLocalizations l10n) => switch (preset) {
    RampPreset.gentle => l10n.rampsPresetGentle,
    RampPreset.classic => l10n.rampsPresetClassic,
    RampPreset.quick => l10n.rampsPresetQuick,
  };

  /// `170–190°`.
  String range(AppLocalizations l10n) =>
      l10n.rampsRange(startCelsius, endCelsius);

  /// `+5° every 2 min · 8 min`, with [total] from `RampService.duration`.
  String summary(AppLocalizations l10n, Duration total) => l10n.rampsSummary(
    stepCelsius,
    DurationFormatter.short(interval, l10n),
    DurationFormatter.short(total, l10n),
  );
}
