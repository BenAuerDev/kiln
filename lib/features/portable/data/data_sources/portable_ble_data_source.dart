import '../../../../core/ble/ble_client.dart';
import '../../../../core/ble/ble_connection_state.dart';

/// I/O on the single Venty/Veazy characteristic (write + notify).
class PortableBleDataSource {
  PortableBleDataSource(this._ble);

  final BleClient _ble;

  static const serviceUuid = '00000000-5354-4f52-5a26-4249434b454c';
  static const characteristicUuid = '00000001-5354-4f52-5a26-4249434b454c';

  Stream<List<int>> subscribe(String deviceId) =>
      _ble.subscribe(deviceId, serviceUuid, characteristicUuid);

  Future<void> enableNotifications(String deviceId) =>
      _ble.enableNotifications(deviceId, serviceUuid, characteristicUuid);

  Stream<BleConnectionState> connectionState(String deviceId) =>
      _ble.connectionState(deviceId);

  Future<void> write(String deviceId, List<int> bytes) =>
      _ble.write(deviceId, serviceUuid, characteristicUuid, bytes);
}
