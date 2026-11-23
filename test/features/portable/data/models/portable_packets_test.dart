import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/data/models/portable_packets.dart';
import 'package:kiln/features/portable/data/models/portable_protocol.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  test('status poll is 01 00 and 18 zero bytes', () {
    expect(PortablePackets.statusPoll(), packet({0: 0x01}));
  });

  test('firmware info request is 02 and 19 zero bytes', () {
    expect(PortablePackets.firmwareInfoRequest(), packet({0: 0x02}));
  });

  test('experimental boost sets only the heater mask and mode 2', () {
    expect(PortablePackets.heaterBoost(), packet({0: 0x01, 1: 0x20, 11: 0x02}));
  });

  test('identity request is 05 and 19 zero bytes', () {
    expect(PortablePackets.identityRequest(), packet({0: 0x05}));
  });

  test('device settings read is 06 and 6 zero bytes', () {
    expect(PortablePackets.deviceSettingsRead(), [6, 0, 0, 0, 0, 0, 0]);
  });

  group('target temperature', () {
    test('185 °C is 01 02 00 00 3A 07', () {
      expect(
        PortablePackets.targetTemperature(185),
        packet({0: 0x01, 1: 0x02, 4: 0x3A, 5: 0x07}),
      );
    });

    test('40 °C and 210 °C encode at the limits', () {
      expect(
        PortablePackets.targetTemperature(40),
        packet({0: 0x01, 1: 0x02, 4: 0x90, 5: 0x01}),
      );
      expect(
        PortablePackets.targetTemperature(210),
        packet({0: 0x01, 1: 0x02, 4: 0x34, 5: 0x08}),
      );
    });

    test('rejects values outside 40–210 °C', () {
      expect(() => PortablePackets.targetTemperature(39), throwsRangeError);
      expect(() => PortablePackets.targetTemperature(211), throwsRangeError);
    });
  });

  test('boost offset fills only byte 6 with mask 0x04', () {
    expect(PortablePackets.boostOffset(15), packet({0: 0x01, 1: 0x04, 6: 15}));
    expect(() => PortablePackets.boostOffset(0), throwsRangeError);
  });

  test('superboost offset fills only byte 7 with mask 0x08', () {
    expect(
      PortablePackets.superBoostOffset(12),
      packet({0: 0x01, 1: 0x08, 7: 12}),
    );
    expect(() => PortablePackets.superBoostOffset(100), throwsRangeError);
  });

  test('heater on/off fills byte 11 with mask 0x20', () {
    expect(
      PortablePackets.heater(on: true),
      packet({0: 0x01, 1: 0x20, 11: 0x01}),
    );
    expect(PortablePackets.heater(on: false), packet({0: 0x01, 1: 0x20}));
  });

  group('settings', () {
    final cases = {
      PortableWritableSetting.fahrenheit: 0x01,
      PortableWritableSetting.ecoCharge: 0x08,
      PortableWritableSetting.ecoVoltage: 0x20,
      PortableWritableSetting.boostVisualisation: 0x40,
    };
    cases.forEach((setting, bit) {
      test('${setting.name} sets byte 14 to the value and byte 15 to $bit', () {
        expect(
          PortablePackets.setting(setting, set: true),
          packet({0: 0x01, 1: 0x80, 14: bit, 15: bit}),
        );
        expect(
          PortablePackets.setting(setting, set: false),
          packet({0: 0x01, 1: 0x80, 15: bit}),
        );
      });
    });

    test('no writable setting uses the factory-reset bit 0x04', () {
      for (final setting in PortableWritableSetting.values) {
        expect(setting.bit & 0x04, 0);
        expect(PortablePackets.setting(setting, set: true)[15] & 0x04, 0);
      }
    });
  });

  test('vibration is a 7-byte 06 08 packet with byte 5 = on', () {
    expect(PortablePackets.vibration(on: true), [6, 8, 0, 0, 0, 1, 0]);
    expect(PortablePackets.vibration(on: false), [6, 8, 0, 0, 0, 0, 0]);
  });

  test('find device is 0D 01', () {
    expect(PortablePackets.findDevice(), packet({0: 0x0D, 1: 0x01}));
  });

  test('every 0x01 write sets only the mask bit of the bytes it fills', () {
    final writes = {
      0x02: PortablePackets.targetTemperature(200),
      0x04: PortablePackets.boostOffset(5),
      0x08: PortablePackets.superBoostOffset(5),
      0x20: PortablePackets.heater(on: true),
      0x80: PortablePackets.setting(
        PortableWritableSetting.fahrenheit,
        set: true,
      ),
    };
    writes.forEach((mask, bytes) {
      expect(bytes, hasLength(20));
      expect(bytes[0], 0x01);
      expect(bytes[1], mask);
    });
  });
}
