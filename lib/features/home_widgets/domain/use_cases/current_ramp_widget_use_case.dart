import '../../../../core/service_locator.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../../../portable/domain/repositories/portable_repository.dart';
import '../../../ramps/domain/repositories/ramp_run_repository.dart';
import '../../../ramps/domain/repositories/ramps_repository.dart';
import '../../../ramps/domain/use_cases/find_ramp_use_case.dart';
import '../models/ramp_widget_snapshot.dart';
import '../services/home_widget_snapshot_service.dart';

/// What the ramp widget should show now, `null` to leave it as it is.
/// Reads repository signals, so it can be used in a computed.
class CurrentRampWidgetUseCase {
  CurrentRampWidgetUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    PortableRepository? portable,
    RampRunRepository? runs,
    RampsRepository? userRamps,
    FindRampUseCase? findRamp,
    HomeWidgetSnapshotService? service,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _portable = portable ?? sl<PortableRepository>(),
       _runs = runs ?? sl<RampRunRepository>(),
       _userRamps = userRamps ?? sl<RampsRepository>(),
       _findRamp = findRamp ?? sl<FindRampUseCase>(),
       _service = service ?? sl<HomeWidgetSnapshotService>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final PortableRepository _portable;
  final RampRunRepository _runs;
  final RampsRepository _userRamps;
  final FindRampUseCase _findRamp;
  final HomeWidgetSnapshotService _service;

  RampWidgetSnapshot? call() => _service.ramp(
    device: _knownDevices.activeDevice.value,
    connection: _connection.status.value,
    status: _portable.status.value,
    session: _portable.sessionNumber.value,
    run: _runs.run.value,
    chosen: _findRamp(_userRamps.selectedId.value).toNullable(),
  );
}
