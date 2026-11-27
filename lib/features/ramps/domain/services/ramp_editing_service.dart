import '../../../portable/domain/services/portable_temperature_limits.dart';
import '../models/ramp_field.dart';
import '../models/ramp_profile.dart';

/// Pure edits for the ramp editor. Every result is within the limits and
/// ends above its start, so the editor never holds a value the use case
/// would have to fix.
class RampEditingService {
  static const temperatureStep = 5;
  static const minStep = 1;
  static const maxStep = 25;
  static const minInterval = Duration(seconds: 15);
  static const maxInterval = Duration(minutes: 10);
  static const intervalStep = Duration(seconds: 15);
  static const maxNameLength = 40;

  static const _min = PortableTemperatureLimits.minTemperature;
  static const _max = PortableTemperatureLimits.maxTemperature;

  /// One −/+ tap on [field]: [temperatureStep] °C for start and end, 1 °C
  /// for the step size, [intervalStep] for the interval. [direction] is `-1`
  /// or `1`. Raising the start past the end pushes the end up; lowering the
  /// end below the start pulls the start down. Returns [profile] itself when
  /// nothing changes, or when clamping would move the value against
  /// [direction] (a stored value off the 5° grid near a limit).
  RampProfile adjust(RampProfile profile, RampField field, int direction) {
    final next = switch (field) {
      RampField.start => _withStart(
        profile,
        (profile.startCelsius + direction * temperatureStep).clamp(
          _min,
          _max - temperatureStep,
        ),
      ),
      RampField.end => _withEnd(
        profile,
        (profile.endCelsius + direction * temperatureStep).clamp(
          _min + temperatureStep,
          _max,
        ),
      ),
      RampField.step => profile.copyWith(
        stepCelsius: (profile.stepCelsius + direction).clamp(minStep, maxStep),
      ),
      RampField.interval => profile.copyWith(
        interval: _clampInterval(profile.interval + intervalStep * direction),
      ),
    };
    final moved = _value(next, field) - _value(profile, field);
    return moved.sign != direction.sign ? profile : next;
  }

  int _value(RampProfile profile, RampField field) => switch (field) {
    RampField.start => profile.startCelsius,
    RampField.end => profile.endCelsius,
    RampField.step => profile.stepCelsius,
    RampField.interval => profile.interval.inSeconds,
  };

  RampProfile _withStart(RampProfile profile, int start) => profile.copyWith(
    startCelsius: start,
    endCelsius: profile.endCelsius > start
        ? profile.endCelsius
        : start + temperatureStep,
  );

  RampProfile _withEnd(RampProfile profile, int end) => profile.copyWith(
    endCelsius: end,
    startCelsius: profile.startCelsius < end
        ? profile.startCelsius
        : end - temperatureStep,
  );

  Duration _clampInterval(Duration interval) => interval < minInterval
      ? minInterval
      : interval > maxInterval
      ? maxInterval
      : interval;

  /// Brings a ramp into the limits (for ramps read from storage or saved):
  /// 40–210 °C with the end above the start, step and interval clamped.
  RampProfile normalise(RampProfile profile) {
    final start = profile.startCelsius.clamp(_min, _max - 1);
    final end = profile.endCelsius.clamp(start + 1, _max);
    return profile.copyWith(
      startCelsius: start,
      endCelsius: end,
      stepCelsius: profile.stepCelsius.clamp(minStep, maxStep),
      interval: _clampInterval(profile.interval),
    );
  }

  /// A ramp can be saved with a name and its end above its start.
  bool canSave(String name, RampProfile profile) =>
      name.trim().isNotEmpty && profile.endCelsius > profile.startCelsius;
}
