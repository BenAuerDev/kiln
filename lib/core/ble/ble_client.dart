import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_connection_state.dart';
import 'ble_exceptions.dart';
import 'ble_scan_hit.dart';

/// Thin I/O wrapper around flutter_blue_plus, addressed by remote id strings
/// so the rest of the app never touches plugin types.
class BleClient {
  final Map<String, List<BluetoothService>> _services = {};

  Future<bool> get isSupported => FlutterBluePlus.isSupported;

  Stream<bool> get adapterOn => FlutterBluePlus.adapterState.map(
    (state) => state == BluetoothAdapterState.on,
  );

  Stream<List<BleScanHit>> scan({
    List<String> serviceUuids = const [],
    List<String> nameKeywords = const [],
    Duration timeout = const Duration(seconds: 15),
  }) async* {
    await _ensureAdapterOn();
    try {
      await FlutterBluePlus.startScan(
        withServices: serviceUuids.map(Guid.new).toList(),
        withKeywords: nameKeywords,
        timeout: timeout,
      );
    } on FlutterBluePlusException catch (e) {
      throw _mapPluginException(e);
    }
    yield* FlutterBluePlus.scanResults.map(
      (results) => results
          .map(
            (r) => BleScanHit(
              deviceId: r.device.remoteId.str,
              name: r.advertisementData.advName.isNotEmpty
                  ? r.advertisementData.advName
                  : r.device.platformName,
              rssi: r.rssi,
              serviceUuids: r.advertisementData.serviceUuids
                  .map((g) => g.str128)
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Future<void> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await _ensureAdapterOn();
    final device = BluetoothDevice.fromId(deviceId);
    try {
      await device.connect(license: License.nonprofit, timeout: timeout);
      _services[deviceId] = await device.discoverServices();
    } on FlutterBluePlusException catch (e) {
      throw _mapPluginException(e);
    } on TimeoutException {
      throw BleTimeoutException('connect $deviceId');
    }
  }

  Future<void> disconnect(String deviceId) async {
    _services.remove(deviceId);
    try {
      await BluetoothDevice.fromId(deviceId).disconnect();
    } on FlutterBluePlusException catch (e) {
      throw _mapPluginException(e);
    }
  }

  Stream<BleConnectionState> connectionState(String deviceId) =>
      BluetoothDevice.fromId(deviceId).connectionState.map(
        (state) => state == BluetoothConnectionState.connected
            ? BleConnectionState.connected
            : BleConnectionState.disconnected,
      );

  Future<List<int>> read(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final characteristic = _characteristic(
      deviceId,
      serviceUuid,
      characteristicUuid,
    );
    try {
      final value = await characteristic.read();
      _log('rd', characteristicUuid, value);
      return value;
    } on FlutterBluePlusException catch (e) {
      throw _mapPluginException(e);
    }
  }

  Future<void> write(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
    List<int> value, {
    bool withResponse = true,
  }) async {
    final characteristic = _characteristic(
      deviceId,
      serviceUuid,
      characteristicUuid,
    );
    _log('tx', characteristicUuid, value);
    try {
      await characteristic.write(value, withoutResponse: !withResponse);
    } on FlutterBluePlusException catch (e) {
      throw _mapPluginException(e);
    }
  }

  /// Completes once the peripheral has acknowledged the notify request, so
  /// the first command sent afterwards cannot race its reply.
  Future<void> enableNotifications(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final characteristic = _characteristic(
      deviceId,
      serviceUuid,
      characteristicUuid,
    );
    try {
      await characteristic.setNotifyValue(true);
    } on FlutterBluePlusException catch (e) {
      throw _mapPluginException(e);
    }
  }

  Stream<List<int>> subscribe(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async* {
    final characteristic = _characteristic(
      deviceId,
      serviceUuid,
      characteristicUuid,
    );
    try {
      await characteristic.setNotifyValue(true);
    } on FlutterBluePlusException catch (e) {
      throw _mapPluginException(e);
    }
    yield* characteristic.onValueReceived.map((value) {
      _log('rx', characteristicUuid, value);
      return value;
    });
  }

  BluetoothCharacteristic _characteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) {
    final services = _services[deviceId];
    if (services == null) {
      throw BleConnectionException('not connected: $deviceId');
    }
    final service = services.where((s) => s.uuid == Guid(serviceUuid));
    if (service.isEmpty) {
      throw BleCharacteristicNotFoundException('service $serviceUuid');
    }
    final characteristic = service.first.characteristics.where(
      (c) => c.uuid == Guid(characteristicUuid),
    );
    if (characteristic.isEmpty) {
      throw BleCharacteristicNotFoundException(
        'characteristic $characteristicUuid',
      );
    }
    return characteristic.first;
  }

  /// Debug builds only: one line per packet, e.g.
  /// `kiln ble 18:42:07.123 tx 00000001 01 02 00 00 3a 07 …`.
  void _log(String direction, String characteristicUuid, List<int> value) {
    if (!kDebugMode) return;
    final hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final time = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint(
      'kiln ble $time $direction ${characteristicUuid.substring(0, 8)} $hex',
    );
  }

  Future<void> _ensureAdapterOn() async {
    if (!await FlutterBluePlus.isSupported) {
      throw const BleUnavailableException('Bluetooth LE not supported');
    }
    final state = await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        // iOS reports `unknown` while the first permission prompt is open.
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
    if (state == BluetoothAdapterState.unauthorized) {
      throw const BlePermissionException('Bluetooth permission denied');
    }
    if (state != BluetoothAdapterState.on) {
      throw BleUnavailableException('adapter state: ${state.name}');
    }
  }

  BleException _mapPluginException(FlutterBluePlusException e) {
    final description = e.description ?? e.function;
    if (description.toLowerCase().contains('permission')) {
      return BlePermissionException(description);
    }
    if (description.toLowerCase().contains('timeout')) {
      return BleTimeoutException(description);
    }
    return BleOperationException(description);
  }
}
