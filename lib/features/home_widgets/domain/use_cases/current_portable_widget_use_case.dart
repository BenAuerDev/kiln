import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../../../portable/domain/repositories/portable_repository.dart';
import '../models/portable_widget_snapshot.dart';
import '../services/home_widget_snapshot_service.dart';

/// What the Venty/Veazy widget should show now, `null` to leave it as it
/// is. Reads repository signals, so it can be used in a computed.
class CurrentPortableWidgetUseCase {
  CurrentPortableWidgetUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    PortableRepository? portable,
    HomeWidgetSnapshotService? service,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _portable = portable ?? sl<PortableRepository>(),
       _service = service ?? sl<HomeWidgetSnapshotService>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final PortableRepository _portable;
  final HomeWidgetSnapshotService _service;

  PortableWidgetSnapshot? call() => _service.portable(
    device: _knownDevices.activeDevice.value,
    connection: _connection.status.value,
    status: _portable.status.value,
  );
}
