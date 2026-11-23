import '../../../../core/formatters/temperature_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/portable_ladder.dart';

extension PortableLadderX on PortableLadder {
  /// "→ 195°", or "→ 210° max" at the device maximum.
  String boostTargetLabel(AppLocalizations l10n) =>
      _targetLabel(boostTemperature, atMax: boostAtMax, l10n: l10n);

  String superBoostTargetLabel(AppLocalizations l10n) =>
      _targetLabel(superBoostTemperature, atMax: superBoostAtMax, l10n: l10n);

  /// "175–195°": base to superboost temperature.
  String rangeLabel(AppLocalizations l10n) =>
      l10n.portableQuickSetupRange(base, superBoostTemperature);

  /// Screen reader text for the scale bar.
  String scaleLabel(AppLocalizations l10n) => l10n.portableScaleLabel(
    TemperatureFormatter.withUnit(base, l10n),
    TemperatureFormatter.withUnit(boostTemperature, l10n),
    TemperatureFormatter.withUnit(superBoostTemperature, l10n),
  );

  String _targetLabel(
    int celsius, {
    required bool atMax,
    required AppLocalizations l10n,
  }) {
    final degrees = TemperatureFormatter.degrees(celsius, l10n);
    return atMax
        ? l10n.portableLadderToMax(degrees)
        : l10n.portableLadderTo(degrees);
  }
}
