import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/portable_battery.dart';

extension PortableBatteryX on PortableBattery {
  /// "72% battery", "12% battery, low" or "72% · charging".
  String label(AppLocalizations l10n) => charging
      ? l10n.portableBatteryCharging(percent)
      : low
      ? l10n.portableBatteryLow(percent)
      : l10n.portableBatteryLevel(percent);
}
