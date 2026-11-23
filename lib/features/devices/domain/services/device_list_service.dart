import '../extensions/known_device_x.dart';
import '../models/connection_status.dart';
import '../models/discovered_device.dart';
import '../models/known_device.dart';
import '../models/known_device_entry.dart';

class DeviceListService {
  const DeviceListService();

  /// Active device first, then most recently used.
  List<KnownDeviceEntry> knownEntries({
    required List<KnownDevice> devices,
    required String? activeDeviceId,
    required ConnectionStatus status,
    required DateTime now,
  }) {
    final entries = [
      for (final device in devices)
        KnownDeviceEntry(
          device: device,
          status: device.id == activeDeviceId ? status : null,
          daysSinceLastUse: device.daysSinceLastUse(now),
        ),
    ];
    entries.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      final aTime = a.device.lastConnectedAt;
      final bTime = b.device.lastConnectedAt;
      if (aTime == null || bTime == null) {
        return (aTime == null ? 1 : 0) - (bTime == null ? 1 : 0);
      }
      return bTime.compareTo(aTime);
    });
    return List.unmodifiable(entries);
  }

  /// Scan results that are not known devices yet.
  List<DiscoveredDevice> nearbyUnknown({
    required List<DiscoveredDevice> discovered,
    required List<KnownDevice> known,
  }) {
    final knownIds = {for (final device in known) device.id};
    return List.unmodifiable(
      discovered.where((device) => !knownIds.contains(device.id)),
    );
  }
}
