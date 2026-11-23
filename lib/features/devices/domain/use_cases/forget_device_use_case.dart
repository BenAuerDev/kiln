import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/connection_repository.dart';
import '../repositories/known_devices_repository.dart';

/// Removes a known device, disconnecting first if it is the active one.
class ForgetDeviceUseCase {
  ForgetDeviceUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;

  Future<Either<AppError, Unit>> call(String deviceId) async {
    if (_knownDevices.byId(deviceId) == null) {
      return left(const AppError.deviceNotFound());
    }
    if (_connection.activeDeviceId.value == deviceId) {
      // A failed BLE disconnect still resets the connection state, so the
      // device is forgotten either way.
      await _connection.disconnect();
    }
    return _knownDevices.remove(deviceId);
  }
}
