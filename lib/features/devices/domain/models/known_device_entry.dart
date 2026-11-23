import 'connection_status.dart';
import 'known_device.dart';

/// A known device as shown in the device list.
class KnownDeviceEntry {
  const KnownDeviceEntry({
    required this.device,
    this.status,
    this.daysSinceLastUse,
  });

  final KnownDevice device;

  /// Only set for the active device.
  final ConnectionStatus? status;
  final int? daysSinceLastUse;

  bool get isActive => status != null;

  @override
  bool operator ==(Object other) =>
      other is KnownDeviceEntry &&
      other.device == device &&
      other.status == status &&
      other.daysSinceLastUse == daysSinceLastUse;

  @override
  int get hashCode => Object.hash(device, status, daysSinceLastUse);
}
