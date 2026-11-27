import '../../../devices/domain/models/device_finish.dart';
import '../../../ramps/domain/models/ramp_profile.dart';

/// Where the ramp on the widget stands.
enum RampWidgetPhase {
  /// Nothing runs; the widget offers the chosen ramp.
  idle,
  running,

  /// A step is due but waits for boost to end.
  waitingForBoost,

  /// The last step was written; the base stays there.
  finished,
}

/// What the ramp widget shows while kiln is connected to a real (not demo)
/// Venty/Veazy: the chosen or running ramp and how far it got.
class RampWidgetSnapshot {
  const RampWidgetSnapshot({
    required this.profile,
    required this.phase,
    required this.target,
    required this.step,
    required this.steps,
    required this.duration,
    required this.finish,
    this.boosting = false,
    this.nextTarget,
    this.nextStepAt,
  });

  final RampProfile profile;
  final RampWidgetPhase phase;

  /// The base the ramp last wrote; its start while idle.
  final int target;

  /// Steps written after the start, of [steps] (the ring).
  final int step;
  final int steps;

  /// Boost is on: target writes are blocked, so a ramp cannot start.
  final bool boosting;

  /// The whole ramp, start to last step.
  final Duration duration;
  final int? nextTarget;

  /// When [nextTarget] is due; only while running and the last write
  /// went through (a failed one is retried at once, not counted down).
  final DateTime? nextStepAt;
  final DeviceFinish finish;

  bool get isRunning =>
      phase == RampWidgetPhase.running ||
      phase == RampWidgetPhase.waitingForBoost;

  @override
  bool operator ==(Object other) =>
      other is RampWidgetSnapshot &&
      other.profile == profile &&
      other.phase == phase &&
      other.target == target &&
      other.step == step &&
      other.steps == steps &&
      other.duration == duration &&
      other.boosting == boosting &&
      other.nextTarget == nextTarget &&
      other.nextStepAt == nextStepAt &&
      other.finish == finish;

  @override
  int get hashCode => Object.hash(
    profile,
    phase,
    target,
    step,
    steps,
    duration,
    boosting,
    nextTarget,
    nextStepAt,
    finish,
  );
}
