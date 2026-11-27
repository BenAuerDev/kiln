import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/domain/models/portable_battery.dart';

void main() {
  group('low', () {
    test('at or below 15% when not charging', () {
      expect(const PortableBattery(percent: 15, charging: false).low, isTrue);
      expect(const PortableBattery(percent: 0, charging: false).low, isTrue);
    });

    test('not above 15%', () {
      expect(const PortableBattery(percent: 16, charging: false).low, isFalse);
    });

    test('never while charging', () {
      expect(const PortableBattery(percent: 5, charging: true).low, isFalse);
    });
  });
}
