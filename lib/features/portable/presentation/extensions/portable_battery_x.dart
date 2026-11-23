import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/portable_battery.dart';

extension PortableBatteryX on PortableBattery {
  String label(AppLocalizations l10n) => charging
      ? l10n.portableBatteryCharging(percent)
      : l10n.portableBatteryLevel(percent);
}
