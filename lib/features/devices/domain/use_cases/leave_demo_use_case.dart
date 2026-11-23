import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/connection_repository.dart';
import '../repositories/known_devices_repository.dart';

/// Disconnects the demo device if it is active and forgets it. Unlike a
/// disconnect by the user, auto-reconnect to the last real device stays on.
/// Returns `none()` when no demo was running.
class LeaveDemoUseCase {
  LeaveDemoUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;

  Future<Either<AppError, Option<Unit>>> call() async {
    final demo = _knownDevices.demoDevice.value;
    if (demo == null) return right(none());
    if (_connection.activeDeviceId.value == demo.id) {
      final disconnected = await _connection.disconnect(byUser: false);
      if (disconnected case Left(value: final error)) return left(error);
    }
    final removed = await _knownDevices.remove(demo.id);
    return removed.map((_) => some(unit));
  }
}
