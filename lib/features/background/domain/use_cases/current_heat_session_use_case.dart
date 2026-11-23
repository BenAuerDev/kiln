import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../../../portable/domain/repositories/portable_repository.dart';
import '../../../volcano/domain/repositories/volcano_repository.dart';
import '../../../workflows/domain/repositories/workflow_run_repository.dart';
import '../models/heat_session.dart';
import '../services/heat_session_service.dart';

/// The active device's heat session, or `null` while nothing heats; see
/// `HeatSessionService.session` for [previous]. Reads repository signals,
/// so it can be used in a computed.
class CurrentHeatSessionUseCase {
  CurrentHeatSessionUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    PortableRepository? portable,
    VolcanoRepository? volcano,
    WorkflowRunRepository? workflowRuns,
    HeatSessionService? service,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _portable = portable ?? sl<PortableRepository>(),
       _volcano = volcano ?? sl<VolcanoRepository>(),
       _workflowRuns = workflowRuns ?? sl<WorkflowRunRepository>(),
       _service = service ?? sl<HeatSessionService>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final PortableRepository _portable;
  final VolcanoRepository _volcano;
  final WorkflowRunRepository _workflowRuns;
  final HeatSessionService _service;

  HeatSession? call({HeatSession? previous}) {
    final device = _knownDevices.activeDevice.value;
    return _service.session(
      device: device,
      startFailed: device?.model == DeviceModel.volcanoHybrid
          ? _volcano.startFailed.value
          : _portable.startFailed.value,
      connection: _connection.status.value,
      previous: previous,
      portable: _portable.status.value,
      volcano: _volcano.status.value,
      workflow: _workflowRuns.run.value,
    );
  }
}
