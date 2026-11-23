import 'device_model.dart';

class DiscoveredDevice {
  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.model,
    required this.rssi,
  });

  final String id;
  final String name;
  final DeviceModel model;
  final int rssi;

  @override
  bool operator ==(Object other) =>
      other is DiscoveredDevice &&
      other.id == id &&
      other.name == name &&
      other.model == model &&
      other.rssi == rssi;

  @override
  int get hashCode => Object.hash(id, name, model, rssi);
}
