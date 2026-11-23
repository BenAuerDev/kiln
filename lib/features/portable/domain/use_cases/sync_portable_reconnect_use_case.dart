import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../models/heater_mode.dart';
import '../models/portable_status.dart';

/// A Venty or Veazy that is not heating hangs up on its own to go to sleep,
/// and buzzes on every reconnect. So a dropped connection is only restored
/// while the heater is on.
class SyncPortableReconnectUseCase {
  SyncPortableReconnectUseCase({ConnectionRepository? connection})
    : _connection = connection ?? sl<ConnectionRepository>();

  final ConnectionRepository _connection;

  void call(PortableStatus status) =>
      _connection.setReconnectAfterDrop(status.heaterMode != HeaterMode.off);
}
