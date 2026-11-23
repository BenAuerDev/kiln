/// Whether the "ready" alert of the current heat-up was already given.
class ReadyAlertState {
  const ReadyAlertState({this.alertedTarget, this.showing = false});

  /// The target of the heat-up that was announced (or seen in front);
  /// `null` while armed.
  final int? alertedTarget;

  /// An alert is in the notification shade.
  final bool showing;

  @override
  bool operator ==(Object other) =>
      other is ReadyAlertState &&
      other.alertedTarget == alertedTarget &&
      other.showing == showing;

  @override
  int get hashCode => Object.hash(alertedTarget, showing);
}

/// What to do after a [ReadyAlertState] step.
enum ReadyAlertAction { none, alert, dismiss }
