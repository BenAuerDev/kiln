import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/known_device_entry.dart';
import 'connection_status_x.dart';

extension KnownDeviceEntryX on KnownDeviceEntry {
  String subtitle(AppLocalizations l10n) {
    final status = this.status;
    if (status != null) return status.label(l10n);
    final days = daysSinceLastUse;
    return days == null ? l10n.devicesNeverUsed : l10n.devicesLastUsed(days);
  }
}
