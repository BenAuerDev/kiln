import '../../../devices/domain/extensions/known_device_x.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/models/known_device.dart';
import '../../../portable/domain/models/heater_mode.dart';
import '../../../portable/domain/models/portable_status.dart';
import '../../../portable/domain/services/portable_temperature_limits.dart';
import '../../../volcano/domain/extensions/volcano_status_x.dart';
import '../../../volcano/domain/models/volcano_heat_phase.dart';
import '../../../volcano/domain/models/volcano_status.dart';
import '../../../workflows/domain/models/workflow_run.dart';
import '../models/heat_session.dart';

/// Pure rules: is the active device heating, and what does it show.
class HeatSessionService {
  /// `null` while nothing heats: no connected device, heater off and no
  /// workflow running on it. While kiln reconnects after a short drop, and
  /// until the reconnected device reports its status again, the [previous]
  /// session is kept, so the service (which Android will not restart from
  /// the background) stays up; not after a failed session start
  /// ([startFailed]), when nothing would ever report again. Demo devices
  /// never get one.
  HeatSession? session({
    required KnownDevice? device,
    required ConnectionStatus connection,
    required PortableStatus? portable,
    required VolcanoStatus? volcano,
    required WorkflowRun? workflow,
    bool startFailed = false,
    HeatSession? previous,
  }) {
    if (device == null || device.isDemo) return null;
    if (connection == ConnectionStatus.reconnecting) return previous;
    if (connection != ConnectionStatus.connected) return null;
    final model = device.model;
    if (model == DeviceModel.volcanoHybrid) {
      final status = volcano;
      if (status == null) return startFailed ? null : previous;
      final run =
          workflow != null &&
              workflow.isActive &&
              workflow.deviceId == device.id
          ? workflow
          : null;
      if (!status.heaterOn && run == null) return null;
      return HeatSession(
        model: model,
        temperature: (status.currentTemperature ?? status.targetTemperature)
            .round(),
        target: status.targetTemperature,
        ready: status.phase == VolcanoHeatPhase.ready,
        workflow: run,
      );
    }
    final status = portable;
    if (status == null) return startFailed ? null : previous;
    if (status.heaterMode == HeaterMode.off) return null;
    final offset = switch (status.heaterMode) {
      HeaterMode.boost => status.boostOffset,
      HeaterMode.superboost => status.boostOffset + status.superBoostOffset,
      _ => 0,
    };
    final setpoint = PortableTemperatureLimits.clampTemperature(
      status.targetTemperature + offset,
    );
    return HeatSession(
      model: model,
      temperature: setpoint,
      target: setpoint,
      ready: status.setpointReached,
      batteryPercent: status.batteryPercent,
      boostTarget: status.heaterMode == HeaterMode.normal
          ? PortableTemperatureLimits.clampTemperature(
              status.targetTemperature + status.boostOffset,
            )
          : null,
    );
  }
}
