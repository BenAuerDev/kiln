import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../../../volcano/domain/repositories/volcano_repository.dart';
import '../models/volcano_widget_snapshot.dart';
import '../services/home_widget_snapshot_service.dart';

/// What the Volcano widget should show live now, `null` for offline; see
/// `HomeWidgetSnapshotService.volcano` for [previous]. Reads repository
/// signals, so it can be used in a computed.
class CurrentVolcanoWidgetUseCase {
  CurrentVolcanoWidgetUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    VolcanoRepository? volcano,
    HomeWidgetSnapshotService? service,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _volcano = volcano ?? sl<VolcanoRepository>(),
       _service = service ?? sl<HomeWidgetSnapshotService>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final VolcanoRepository _volcano;
  final HomeWidgetSnapshotService _service;

  VolcanoWidgetSnapshot? call({VolcanoWidgetSnapshot? previous}) =>
      _service.volcano(
        device: _knownDevices.activeDevice.value,
        connection: _connection.status.value,
        status: _volcano.status.value,
        startFailed: _volcano.startFailed.value,
        previous: previous,
      );
}
