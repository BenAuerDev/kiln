import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/domain/extensions/known_device_x.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/models/known_device.dart';
import '../../../portable/domain/extensions/portable_status_x.dart';
import '../../../portable/domain/models/portable_status.dart';
import '../../../portable/domain/services/portable_ladder_service.dart';
import '../../../ramps/domain/models/ramp_profile.dart';
import '../../../ramps/domain/models/ramp_run.dart';
import '../../../ramps/domain/services/ramp_service.dart';
import '../../../volcano/domain/extensions/volcano_status_x.dart';
import '../../../volcano/domain/models/volcano_status.dart';
import '../models/portable_widget_snapshot.dart';
import '../models/ramp_widget_snapshot.dart';
import '../models/volcano_widget_snapshot.dart';

/// Pure rules: what the home-screen widgets show. Demo devices never reach
/// a widget.
class HomeWidgetSnapshotService {
  const HomeWidgetSnapshotService(
    this._ladder, [
    this._ramps = const RampService(),
  ]);

  final PortableLadderService _ladder;
  final RampService _ramps;

  /// `null` (the widget goes offline and keeps the last values) unless a
  /// real Venty/Veazy is connected and has reported its status.
  PortableWidgetSnapshot? portable({
    required KnownDevice? device,
    required ConnectionStatus connection,
    required PortableStatus? status,
  }) {
    if (device == null || device.isDemo || !device.model.isPortable) {
      return null;
    }
    if (connection != ConnectionStatus.connected || status == null) {
      return null;
    }
    return PortableWidgetSnapshot(
      model: device.model,
      battery: status.battery,
      ladder: _ladder.ladder(status),
      heaterMode: status.heaterMode,
      phase: status.heatPhase,
      activeTemperature: _ladder.activeTemperature(status),
      finish: device.effectiveFinish,
    );
  }

  /// `null` (the widget goes offline and keeps the last values) unless a
  /// real Venty/Veazy is connected and has reported its status. Shows the
  /// ramp that runs, or finished, in this session on this device; otherwise
  /// the [chosen] ramp, ready to start.
  RampWidgetSnapshot? ramp({
    required KnownDevice? device,
    required ConnectionStatus connection,
    required PortableStatus? status,
    required int session,
    required RampRun? run,
    required RampProfile? chosen,
  }) {
    if (device == null || device.isDemo || !device.model.isPortable) {
      return null;
    }
    if (connection != ConnectionStatus.connected || status == null) {
      return null;
    }
    final finish = device.effectiveFinish;
    final current =
        run != null &&
        run.phase != RampRunPhase.stopped &&
        _ramps.isCurrent(
          run,
          deviceId: device.id,
          session: session,
          baseCelsius: status.targetTemperature,
        );
    if (!current) {
      final profile = _ramps.shown(run: null, chosen: chosen);
      return RampWidgetSnapshot(
        profile: profile,
        phase: RampWidgetPhase.idle,
        target: _ramps.targets(profile).first,
        step: 0,
        steps: _ramps.stepCount(profile),
        duration: _ramps.duration(profile),
        boosting: status.boostActive,
        finish: finish,
      );
    }
    final targets = _ramps.targets(run.profile);
    final next = run.nextTarget;
    final phase = !run.isActive || next == null
        ? RampWidgetPhase.finished
        : run.waitingForBoost
        ? RampWidgetPhase.waitingForBoost
        : RampWidgetPhase.running;
    final steps = targets.length - 1;
    return RampWidgetSnapshot(
      profile: run.profile,
      phase: phase,
      target: run.target,
      step: phase == RampWidgetPhase.finished
          ? steps
          : targets.indexOf(run.target).clamp(0, steps),
      steps: steps,
      duration: _ramps.duration(run.profile),
      nextTarget: phase == RampWidgetPhase.finished ? null : next,
      nextStepAt: phase == RampWidgetPhase.running && run.pendingTarget == null
          ? run.nextStepAt
          : null,
      finish: finish,
    );
  }

  /// `null` (the widget goes offline) unless a real Volcano is connected.
  /// While kiln reconnects after a short drop, and until a fresh session
  /// reports its status, the [previous] snapshot is kept, so the widget
  /// does not flicker; not after a failed session start ([startFailed]),
  /// when nothing would ever report again.
  VolcanoWidgetSnapshot? volcano({
    required KnownDevice? device,
    required ConnectionStatus connection,
    required VolcanoStatus? status,
    bool startFailed = false,
    VolcanoWidgetSnapshot? previous,
  }) {
    if (device == null ||
        device.isDemo ||
        device.model != DeviceModel.volcanoHybrid) {
      return null;
    }
    if (connection == ConnectionStatus.reconnecting) return previous;
    if (connection != ConnectionStatus.connected) return null;
    if (status == null) return startFailed ? null : previous;
    final temperature = status.currentTemperature?.round();
    return VolcanoWidgetSnapshot(
      temperature: temperature,
      target: status.targetTemperature,
      phase: status.phase,
      pumpOn: status.pumpOn,
      // From the rounded value, so tenths of a degree do not redraw it.
      progress: temperature == null
          ? 0
          : VolcanoStatusX.gaugeFraction(temperature.toDouble()),
      finish: device.effectiveFinish,
    );
  }
}
