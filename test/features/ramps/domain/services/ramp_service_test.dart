import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/ramps/domain/models/ramp_profile.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';

void main() {
  final service = RampService();
  final classic = RampService.presets[1];

  RampProfile profile(int start, int step, int end) => RampProfile(
    preset: RampPreset.gentle,
    startCelsius: start,
    stepCelsius: step,
    interval: const Duration(minutes: 1),
    endCelsius: end,
  );

  test('steps from start to end', () {
    expect(service.targets(classic), [180, 185, 190, 195, 200]);
    expect(service.duration(classic), const Duration(minutes: 6));
  });

  test('the last step lands on the end', () {
    expect(service.targets(profile(180, 7, 200)), [180, 187, 194, 200]);
  });

  test('clamped to 40–210 °C; a flat or reversed range is one step', () {
    expect(service.targets(profile(200, 10, 230)), [200, 210]);
    expect(service.targets(profile(20, 30, 60)), [40, 60]);
    expect(service.targets(profile(190, 5, 180)), [190]);
    expect(service.targets(profile(190, 0, 200)), [190]);
  });

  test('next', () {
    expect(service.next(classic, 180), 185);
    expect(service.next(classic, 197), 200);
    expect(service.next(classic, 200), isNull);
  });

  test('presets all go up', () {
    for (final preset in RampService.presets) {
      expect(service.targets(preset).length, greaterThan(1));
    }
  });

  group('isCurrent', () {
    final running = RampRun(
      profile: classic,
      deviceId: 'v',
      session: 3,
      target: 185,
      nextStepAt: DateTime(2026),
    );

    test('same device and session', () {
      expect(
        service.isCurrent(running, deviceId: 'v', session: 3, baseCelsius: 1),
        isTrue,
      );
      expect(
        service.isCurrent(running, deviceId: 'w', session: 3, baseCelsius: 185),
        isFalse,
      );
      expect(
        service.isCurrent(running, deviceId: 'v', session: 4, baseCelsius: 185),
        isFalse,
      );
    });

    test('a finished ramp only while the base is still its last step', () {
      final done = running.copyWith(target: 200, phase: RampRunPhase.finished);
      expect(
        service.isCurrent(done, deviceId: 'v', session: 3, baseCelsius: 200),
        isTrue,
      );
      expect(
        service.isCurrent(done, deviceId: 'v', session: 3, baseCelsius: 190),
        isFalse,
      );
    });
  });
}
