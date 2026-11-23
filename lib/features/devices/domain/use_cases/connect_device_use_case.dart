import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/known_device.dart';
import '../repositories/connection_repository.dart';
import '../repositories/known_devices_repository.dart';
import '../repositories/scan_repository.dart';

/// Connects to a known device or to one from the current scan results,
/// remembers it with the connection time and makes it the device kiln
/// reconnects to.
class ConnectDeviceUseCase {
  ConnectDeviceUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    ScanRepository? scan,
    DateTime Function()? clock,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _scan = scan ?? sl<ScanRepository>(),
       _clock = clock ?? DateTime.now;

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final ScanRepository _scan;
  final DateTime Function() _clock;

  Future<Either<AppError, KnownDevice>> call(String deviceId) async {
    final known = _knownDevices.byId(deviceId);
    final discovered = _scan.results.value
        .where((d) => d.id == deviceId)
        .firstOrNull;
    final base =
        known ??
        (discovered == null
            ? null
            : KnownDevice(
                id: discovered.id,
                name: discovered.name,
                model: discovered.model,
              ));
    if (base == null) return left(const AppError.deviceNotFound());

    // Scanning while connecting makes Android connections flaky.
    if (_scan.scanning.value) await _scan.stop();

    final connected = await _connection.connect(deviceId);
    if (connected case Left(value: final error)) return left(error);

    final device = base.copyWith(lastConnectedAt: _clock());
    final saved = await _knownDevices.save(device);
    if (saved case Left(value: final error)) return left(error);
    final remembered = await _knownDevices.setLastDeviceId(deviceId);
    if (remembered case Left(value: final error)) return left(error);
    return right(device);
  }
}
