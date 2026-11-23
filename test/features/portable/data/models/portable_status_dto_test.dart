import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/data/models/portable_protocol.dart';
import 'package:kiln/features/portable/data/models/portable_status_dto.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  group('PortableStatusDto.decode', () {
    test('decodes a heating status packet', () {
      // Heating normally, 184.2 °C of 185.0 °C, boost +15, superboost +10,
      // 76 % battery, charger connected, 90 s auto-off, setpoint reached,
      // eco charge and boost visualisation set, BLE permanent.
      final bytes = [
        0x01, 0x00, 0x32, 0x07, 0x3A, 0x07, 0x0F, 0x0A, 0x4C, 0x5A, //
        0x00, 0x01, 0x00, 0x01, 0x4A, 0x00, 0x01, 0x00, 0x00, 0x00,
      ];

      final dto = PortableStatusDto.decode(bytes);

      expect(dto.currentTemperatureTenths, 1842);
      expect(dto.targetTemperatureTenths, 1850);
      expect(dto.boostOffset, 15);
      expect(dto.superBoostOffset, 10);
      expect(dto.batteryPercent, 76);
      expect(dto.autoOffSeconds, 90);
      expect(dto.heaterModeCode, PortableHeaterModeCode.normal);
      expect(dto.chargerConnected, isTrue);
      expect(dto.settingsBits, 0x4A);
      expect(dto.hasSetting(PortableSettingsBit.setpointReached), isTrue);
      expect(dto.hasSetting(PortableSettingsBit.ecoCharge), isTrue);
      expect(dto.hasSetting(PortableSettingsBit.boostVisualisation), isTrue);
      expect(dto.hasSetting(PortableSettingsBit.fahrenheit), isFalse);
      expect(dto.settings2Bits, PortableSettings2Bit.blePermanent);
    });

    test('0x8000 current temperature means no reading', () {
      final dto = PortableStatusDto.decode(statusPacket(currentTenths: 0x8000));

      expect(dto.currentTemperatureTenths, isNull);
      expect(dto.targetTemperatureTenths, 1800);
    });

    test('auto-off is the sum of bytes 9 and 10 like the official app', () {
      final dto = PortableStatusDto.decode(
        statusPacket(autoOffLow: 100, autoOffHigh: 20),
      );

      expect(dto.autoOffSeconds, 120);
    });

    test('decodes all heater modes', () {
      for (final mode in [0, 1, 2, 3]) {
        expect(
          PortableStatusDto.decode(
            statusPacket(heaterMode: mode),
          ).heaterModeCode,
          mode,
        );
      }
    });

    test('a 15-byte packet decodes without settings2', () {
      final dto = PortableStatusDto.decode(statusPacket(length: 15));

      expect(dto.settings2Bits, isNull);
      expect(dto.boostOffset, 15);
    });

    test('a 16-byte packet has no settings2 either', () {
      expect(
        PortableStatusDto.decode(statusPacket(length: 16)).settings2Bits,
        isNull,
      );
    });

    test('a 17-byte packet carries settings2', () {
      expect(
        PortableStatusDto.decode(
          statusPacket(length: 17, settings2: 1),
        ).settings2Bits,
        1,
      );
    });

    test('throws FormatException for a short packet', () {
      expect(
        () => PortableStatusDto.decode(statusPacket(length: 14)),
        throwsFormatException,
      );
      expect(() => PortableStatusDto.decode(const []), throwsFormatException);
    });

    test('throws FormatException for another command', () {
      expect(
        () => PortableStatusDto.decode(statusPacket()..[0] = 0x02),
        throwsFormatException,
      );
    });

    test('throws FormatException for an unknown heater mode', () {
      expect(
        () => PortableStatusDto.decode(statusPacket(heaterMode: 4)),
        throwsFormatException,
      );
    });
  });
}
