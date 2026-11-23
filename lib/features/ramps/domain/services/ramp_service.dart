import '../../../portable/domain/services/portable_temperature_limits.dart';
import '../models/ramp_profile.dart';
import '../models/ramp_run.dart';

/// Pure rules of a ramp: the presets, the temperatures it steps through and
/// how long it takes.
class RampService {
  static const presets = [
    RampProfile(
      preset: RampPreset.gentle,
      startCelsius: 170,
      stepCelsius: 5,
      interval: Duration(minutes: 2),
      endCelsius: 190,
    ),
    RampProfile(
      preset: RampPreset.classic,
      startCelsius: 180,
      stepCelsius: 5,
      interval: Duration(seconds: 90),
      endCelsius: 200,
    ),
    RampProfile(
      preset: RampPreset.quick,
      startCelsius: 185,
      stepCelsius: 10,
      interval: Duration(minutes: 1),
      endCelsius: 205,
    ),
  ];

  /// Every base temperature of [profile], start to end, within 40–210 °C.
  /// The last step lands exactly on the end even if the step size does not
  /// divide the range.
  List<int> targets(RampProfile profile) {
    final start = PortableTemperatureLimits.clampTemperature(
      profile.startCelsius,
    );
    final end = PortableTemperatureLimits.clampTemperature(profile.endCelsius);
    if (profile.stepCelsius <= 0 || end <= start) return [start];
    return [for (var t = start; t < end; t += profile.stepCelsius) t, end];
  }

  /// The step after [current], or `null` when [current] is the last one.
  int? next(RampProfile profile, int current) {
    for (final target in targets(profile)) {
      if (target > current) return target;
    }
    return null;
  }

  /// Whether [run] belongs to what the device shows now: the same device and
  /// session, and for a finished ramp the base still at its last step.
  bool isCurrent(
    RampRun run, {
    required String? deviceId,
    required int session,
    required int? baseCelsius,
  }) {
    if (run.deviceId != deviceId || run.session != session) return false;
    return run.phase != RampRunPhase.finished || baseCelsius == run.target;
  }

  /// From the start temperature until the last step is written.
  Duration duration(RampProfile profile) =>
      profile.interval * (targets(profile).length - 1);
}
