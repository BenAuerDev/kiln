import 'ramp_profile.dart';

enum RampRunPhase {
  running,

  /// The last step was written; the base stays there.
  finished,

  /// Ended by the user, a manual base change or the heater going off.
  stopped,
}

/// State of the ramp that runs or last ran on a Venty/Veazy.
class RampRun {
  const RampRun({
    required this.profile,
    required this.deviceId,
    required this.session,
    required this.target,
    required this.nextStepAt,
    this.nextTarget,
    this.phase = RampRunPhase.running,
    this.waitingForBoost = false,
    this.heaterOffSince,
    this.pendingTarget,
  });

  final RampProfile profile;

  /// The device the ramp was started on. It never continues on another one.
  final String deviceId;

  /// `PortableRepository.sessionNumber` when the ramp started.
  final int session;

  /// The base temperature kiln last wrote.
  final int target;

  /// When the next step is due.
  final DateTime nextStepAt;

  /// The base after the next step; `null` once the last step was written.
  final int? nextTarget;
  final RampRunPhase phase;

  /// A step is due, but target writes are blocked while boosting; it is
  /// written as soon as boost ends.
  final bool waitingForBoost;

  /// When the heater was first seen off. kiln's own "end boost" briefly
  /// switches it off and on again, so only a lasting off stops the ramp.
  final DateTime? heaterOffSince;

  /// A step whose write reported an error. If the device applied it anyway,
  /// the status shows it; that is not a manual change.
  final int? pendingTarget;

  bool get isActive => phase == RampRunPhase.running;

  RampRun copyWith({
    int? target,
    DateTime? nextStepAt,
    int? nextTarget,
    bool clearNextTarget = false,
    RampRunPhase? phase,
    bool? waitingForBoost,
    DateTime? heaterOffSince,
    bool clearHeaterOffSince = false,
    int? pendingTarget,
    bool clearPendingTarget = false,
  }) => RampRun(
    profile: profile,
    deviceId: deviceId,
    session: session,
    target: target ?? this.target,
    nextStepAt: nextStepAt ?? this.nextStepAt,
    nextTarget: clearNextTarget ? null : nextTarget ?? this.nextTarget,
    phase: phase ?? this.phase,
    waitingForBoost: waitingForBoost ?? this.waitingForBoost,
    heaterOffSince: clearHeaterOffSince
        ? null
        : heaterOffSince ?? this.heaterOffSince,
    pendingTarget: clearPendingTarget
        ? null
        : pendingTarget ?? this.pendingTarget,
  );
}
