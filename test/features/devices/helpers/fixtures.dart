import 'package:kiln/core/ble/ble_scan_hit.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';

final lastWeek = DateTime(2026, 11, 16, 20);
final fixedNow = DateTime(2026, 11, 23, 10);

const veazy = KnownDevice(
  id: 'veazy-id',
  name: 'S&B VZ123456',
  model: DeviceModel.veazy,
);

const volcano = KnownDevice(
  id: 'volcano-id',
  name: 'S&B VOLCANO H',
  model: DeviceModel.volcanoHybrid,
);

const discoveredVenty = DiscoveredDevice(
  id: 'venty-id',
  name: 'S&B VY000042',
  model: DeviceModel.venty,
  rssi: -55,
);

BleScanHit hit(
  String name, {
  String id = 'id',
  int rssi = -60,
  List<String> services = const [],
}) => BleScanHit(deviceId: id, name: name, rssi: rssi, serviceUuids: services);
