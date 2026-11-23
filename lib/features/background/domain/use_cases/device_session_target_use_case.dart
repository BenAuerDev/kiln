import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';

/// The connected active device whose session should run, or `null`. Reads
/// repository signals, so it can be used in a computed.
class DeviceSessionTargetUseCase {
  DeviceSessionTargetUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;

  ({String id, DeviceModel model})? call() {
    final device = _knownDevices.activeDevice.value;
    if (device == null ||
        _connection.status.value != ConnectionStatus.connected) {
      return null;
    }
    return (id: device.id, model: device.model);
  }
}
