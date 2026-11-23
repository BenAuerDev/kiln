import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/portable/domain/services/portable_temperature_limits.dart';

void main() {
  test('clampTemperature keeps 40–210 °C', () {
    expect(PortableTemperatureLimits.clampTemperature(39), 40);
    expect(PortableTemperatureLimits.clampTemperature(180), 180);
    expect(PortableTemperatureLimits.clampTemperature(211), 210);
  });

  test('clampOffset keeps 1–30', () {
    expect(PortableTemperatureLimits.clampOffset(0), 1);
    expect(PortableTemperatureLimits.clampOffset(15), 15);
    expect(PortableTemperatureLimits.clampOffset(31), 30);
  });

  group('step', () {
    Option<int> step(int current, int delta) =>
        PortableTemperatureLimits.step(current, delta, min: 1, max: 30);

    test('moves within the range', () {
      expect(step(10, 1), some(11));
      expect(step(10, -3), some(7));
    });

    test('clamps at the limits', () {
      expect(step(28, 5), some(30));
      expect(step(3, -5), some(1));
    });

    test('returns none when nothing moves', () {
      expect(step(30, 1), none<int>());
      expect(step(1, -1), none<int>());
      expect(step(10, 0), none<int>());
    });

    test('never moves against the requested direction', () {
      expect(step(50, 1), none<int>());
      expect(step(0, -1), none<int>());
      expect(step(50, -1), some(30));
    });
  });
}
