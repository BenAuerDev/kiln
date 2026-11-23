import '../../../../core/ble/ble_scan_hit.dart';
import '../models/device_model.dart';
import '../models/discovered_device.dart';

/// Recognises Storz & Bickel devices in scan results.
///
/// Names and UUIDs follow the official web app (`requestDevice` filters and
/// `whichDeviceConnected()`): Volcano advertises `S&B VOLCANO H`, Venty
/// `S&B VY<serial>`, Veazy `S&B VZ<serial>`. Any other `S&B` or
/// `STORZ&BICKEL` name is treated as a Crafty, as the official app does.
class ScanFilterService {
  const ScanFilterService();

  static const _sbSuffix = '-5354-4f52-5a26-4249434b454c';

  static const volcanoServiceUuids = {
    '10100000$_sbSuffix',
    '10110000$_sbSuffix',
    '10130000$_sbSuffix',
  };

  /// Shared by Venty and Veazy, so it cannot tell them apart.
  static const portableServiceUuid = '00000000$_sbSuffix';

  /// The Crafty UUIDs spell `STORZ&BICKEL` in reverse byte order.
  static const craftyServiceUuids = {
    '00000001-4c45-4b43-4942-265a524f5453',
    '00000002-4c45-4b43-4942-265a524f5453',
    '00000003-4c45-4b43-4942-265a524f5453',
  };

  DeviceModel? modelFor({
    required String name,
    List<String> serviceUuids = const [],
  }) => _modelFromName(name) ?? _modelFromServices(serviceUuids);

  /// S&B devices only, strongest signal first.
  List<DiscoveredDevice> discoveredFrom(List<BleScanHit> hits) {
    final devices = <DiscoveredDevice>[];
    for (final hit in hits) {
      final model = modelFor(name: hit.name, serviceUuids: hit.serviceUuids);
      if (model == null) continue;
      devices.add(
        DiscoveredDevice(
          id: hit.deviceId,
          name: hit.name,
          model: model,
          rssi: hit.rssi,
        ),
      );
    }
    devices.sort((a, b) => b.rssi.compareTo(a.rssi));
    return List.unmodifiable(devices);
  }

  DeviceModel? _modelFromName(String name) {
    final upper = name.trim().toUpperCase();
    if (!upper.startsWith('S&B') && !upper.startsWith('STORZ&BICKEL')) {
      return null;
    }
    if (upper.contains('VOLCANO')) return DeviceModel.volcanoHybrid;
    if (upper.startsWith('S&B VY')) return DeviceModel.venty;
    if (upper.startsWith('S&B VZ')) return DeviceModel.veazy;
    return DeviceModel.craftyPlus;
  }

  DeviceModel? _modelFromServices(List<String> serviceUuids) {
    final uuids = serviceUuids.map((u) => u.toLowerCase()).toSet();
    if (uuids.any(volcanoServiceUuids.contains)) {
      return DeviceModel.volcanoHybrid;
    }
    if (uuids.any(craftyServiceUuids.contains)) return DeviceModel.craftyPlus;
    return null;
  }
}
