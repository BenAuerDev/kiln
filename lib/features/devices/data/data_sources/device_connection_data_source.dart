import '../../../../core/ble/ble_client.dart';
import '../../../../core/ble/ble_connection_state.dart';

class DeviceConnectionDataSource {
  DeviceConnectionDataSource(this._ble);

  final BleClient _ble;

  Future<void> connect(String deviceId) => _ble.connect(deviceId);

  Future<void> disconnect(String deviceId) => _ble.disconnect(deviceId);

  Stream<BleConnectionState> connectionState(String deviceId) =>
      _ble.connectionState(deviceId);
}
