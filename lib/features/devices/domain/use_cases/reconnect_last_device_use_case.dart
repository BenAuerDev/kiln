import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/connection_status.dart';
import '../models/known_device.dart';
import '../repositories/connection_repository.dart';
import '../repositories/known_devices_repository.dart';

/// Reconnects to the last device on app start and resume. Runs the
/// repository's retry job, so the returned future can take a while; callers
/// should not await it on the UI path.
///
/// Returns `none()` when there was nothing to do: no last device, a
/// connection already in progress or up, or the user disconnected on purpose.
class ReconnectLastDeviceUseCase {
  ReconnectLastDeviceUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    DateTime Function()? clock,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _clock = clock ?? DateTime.now;

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final DateTime Function() _clock;

  static const _busy = {
    ConnectionStatus.connecting,
    ConnectionStatus.connected,
    ConnectionStatus.reconnecting,
  };

  Future<Either<AppError, Option<KnownDevice>>> call() async {
    final id = _knownDevices.lastDeviceId.value;
    final device = id == null ? null : _knownDevices.byId(id);
    if (device == null ||
        _connection.disconnectedByUser.value ||
        _busy.contains(_connection.status.value)) {
      return right(none());
    }

    final reconnected = await _connection.reconnect(device.id);
    if (reconnected case Left(value: final error)) return left(error);

    // Forgotten while the job was running: do not bring it back.
    final current = _knownDevices.byId(device.id);
    if (current == null) return right(none());
    final updated = current.copyWith(lastConnectedAt: _clock());
    final saved = await _knownDevices.save(updated);
    if (saved case Left(value: final error)) return left(error);
    return right(some(updated));
  }
}
