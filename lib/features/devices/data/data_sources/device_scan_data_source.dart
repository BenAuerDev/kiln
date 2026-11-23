import '../../../../core/ble/ble_client.dart';
import '../../../../core/ble/ble_scan_hit.dart';

class DeviceScanDataSource {
  DeviceScanDataSource(this._ble);

  final BleClient _ble;

  /// Unfiltered on purpose: Android cannot combine name keywords with service
  /// filters, and not every S&B model advertises its service UUID. Filtering
  /// happens in `ScanFilterService`.
  Stream<List<BleScanHit>> scan(Duration timeout) =>
      _ble.scan(timeout: timeout);

  Future<void> stop() => _ble.stopScan();
}
