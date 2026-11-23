import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/connection_repository.dart';

/// Disconnects on purpose. Auto-reconnect on resume stays off until the next
/// connect; the device remains the one kiln reconnects to on the next start.
class DisconnectDeviceUseCase {
  DisconnectDeviceUseCase({ConnectionRepository? connection})
    : _connection = connection ?? sl<ConnectionRepository>();

  final ConnectionRepository _connection;

  Future<Either<AppError, Unit>> call() => _connection.disconnect();
}
