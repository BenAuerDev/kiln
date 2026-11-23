/// Device ids of the simulated demo devices. `BleClient` routes every id
/// with [prefix] to `BleSimulator` instead of the Bluetooth radio.
abstract final class DemoDeviceIds {
  static const prefix = 'demo:';
  static const volcano = '${prefix}volcano';
  static const venty = '${prefix}venty';
  static const veazy = '${prefix}veazy';

  static bool isDemo(String deviceId) => deviceId.startsWith(prefix);
}
