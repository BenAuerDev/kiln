import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/extensions/known_device_x.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/finish_preference.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('effectiveFinish', () {
    test('match without detection falls back to ember', () {
      expect(veazy.effectiveFinish, DeviceFinish.ember);
    });

    test('match follows the detected finish', () {
      expect(
        veazy.copyWith(detectedFinish: DeviceFinish.pink).effectiveFinish,
        DeviceFinish.pink,
      );
    });

    test('a fixed finish wins over detection', () {
      expect(
        veazy
            .copyWith(
              detectedFinish: DeviceFinish.pink,
              finishPreference: const FixedFinish(DeviceFinish.lava),
            )
            .effectiveFinish,
        DeviceFinish.lava,
      );
    });
  });

  group('daysSinceLastUse', () {
    test('null when never connected', () {
      expect(veazy.daysSinceLastUse(fixedNow), isNull);
    });

    test('counts calendar days, not 24 h blocks', () {
      final lateYesterday = veazy.copyWith(
        lastConnectedAt: DateTime(2026, 11, 22, 23, 50),
      );
      expect(lateYesterday.daysSinceLastUse(DateTime(2026, 11, 23, 0, 10)), 1);
      expect(
        veazy.copyWith(lastConnectedAt: lastWeek).daysSinceLastUse(fixedNow),
        7,
      );
    });

    test('today and clock skew are 0', () {
      expect(
        veazy.copyWith(lastConnectedAt: fixedNow).daysSinceLastUse(fixedNow),
        0,
      );
      expect(
        veazy
            .copyWith(lastConnectedAt: fixedNow.add(const Duration(days: 2)))
            .daysSinceLastUse(fixedNow),
        0,
      );
    });
  });
}
