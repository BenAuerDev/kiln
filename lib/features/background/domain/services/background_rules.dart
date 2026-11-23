import '../models/heat_session.dart';
import '../models/ready_alert_state.dart';

/// Pure rules of the background behaviour.
class BackgroundRules {
  /// The Venty/Veazy poll runs while kiln is in front, and in the
  /// background only while something heats; otherwise it pauses so the
  /// device can sleep (docs/protocol.md).
  bool keepPolling({required bool inFront, required bool heating}) =>
      inFront || heating;

  /// One "ready" alert per heat-up, only while kiln is not in front.
  ///
  /// A heat-up ends when nothing heats any more or the target changes;
  /// holding temperature (dipping under "ready" and back) does not re-arm
  /// it. Being in front counts as seen. An alert still showing is dismissed
  /// when kiln comes to the front or nothing heats any more.
  (ReadyAlertState, ReadyAlertAction) readyAlert(
    ReadyAlertState state, {
    required HeatSession? session,
    required bool inFront,
  }) {
    if (session == null) {
      return (
        const ReadyAlertState(),
        state.showing ? ReadyAlertAction.dismiss : ReadyAlertAction.none,
      );
    }
    final armed =
        state.alertedTarget == null || state.alertedTarget != session.target;
    if (session.ready && armed) {
      return inFront
          ? (
              ReadyAlertState(alertedTarget: session.target),
              ReadyAlertAction.none,
            )
          : (
              ReadyAlertState(alertedTarget: session.target, showing: true),
              ReadyAlertAction.alert,
            );
    }
    final next = ReadyAlertState(
      alertedTarget: armed ? null : state.alertedTarget,
      showing: state.showing && !inFront,
    );
    return (
      next,
      state.showing && inFront
          ? ReadyAlertAction.dismiss
          : ReadyAlertAction.none,
    );
  }
}
