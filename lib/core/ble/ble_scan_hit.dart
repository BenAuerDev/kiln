class BleScanHit {
  const BleScanHit({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.serviceUuids,
  });

  final String deviceId;
  final String name;
  final int rssi;
  final List<String> serviceUuids;
}
