import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/data/safety/portable_write_safety.dart';

void main() {
  test('verified writes are allowed', () {
    for (final write in [
      PortableWrite.statusPoll,
      PortableWrite.firmwareInfoRead,
      PortableWrite.settingsRead,
      PortableWrite.targetTemperature,
      PortableWrite.boostOffset,
      PortableWrite.superBoostOffset,
      PortableWrite.heaterOn,
      PortableWrite.heaterOff,
      PortableWrite.heaterBoost,
      PortableWrite.setting,
      PortableWrite.vibration,
      PortableWrite.findDevice,
    ]) {
      expect(
        PortableWriteSafety.isAllowed(write, boostActive: false),
        isTrue,
        reason: write.name,
      );
    }
  });

  test('superboost is disabled', () {
    expect(
      PortableWriteSafety.isAllowed(
        PortableWrite.heaterSuperBoost,
        boostActive: false,
      ),
      isFalse,
    );
  });

  test('target writes are disabled while boosting', () {
    expect(
      PortableWriteSafety.isAllowed(
        PortableWrite.targetTemperature,
        boostActive: true,
      ),
      isFalse,
    );
    expect(
      PortableWriteSafety.isAllowed(
        PortableWrite.boostOffset,
        boostActive: true,
      ),
      isTrue,
    );
  });
}
