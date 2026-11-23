import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/volcano/data/models/volcano_codec.dart';
import 'package:kiln/features/volcano/data/models/volcano_registers_dto.dart';
import 'package:kiln/features/volcano/data/models/volcano_uuids.dart';
import 'package:kiln/features/volcano/data/models/volcano_write_safety.dart';

void main() {
  group('decodeTemperature', () {
    test('reads uint16 LE tenths of °C', () {
      // 0x0742 = 1858 → 185.8 °C
      expect(VolcanoCodec.decodeTemperature([0x42, 0x07]), 185.8);
      expect(VolcanoCodec.decodeTemperature([0xC5, 0x03]), 96.5);
    });

    test('ignores bytes after the first two', () {
      expect(VolcanoCodec.decodeTemperature([0x42, 0x07, 0x00, 0x00]), 185.8);
      expect(VolcanoCodec.decodeTemperature([0x42, 0x07, 0xFF, 0xFF]), 185.8);
    });

    test('returns null for readings of 6536 °C and above', () {
      expect(VolcanoCodec.decodeTemperature([0x50, 0xFF]), isNull);
      expect(VolcanoCodec.decodeTemperature([0xFF, 0xFF]), isNull);
      expect(VolcanoCodec.decodeTemperature([0x4F, 0xFF]), 6535.9);
    });

    test('throws FormatException on short packets', () {
      expect(
        () => VolcanoCodec.decodeTemperature([0x42]),
        throwsFormatException,
      );
      expect(() => VolcanoCodec.decodeTemperature([]), throwsFormatException);
    });
  });

  group('encodeTargetTemperature', () {
    test('writes uint32 LE tenths of °C', () {
      // 185 °C × 10 = 1850 = 0x073A.
      expect(VolcanoCodec.encodeTargetTemperature(185), [0x3A, 0x07, 0, 0]);
      expect(VolcanoCodec.encodeTargetTemperature(40), [0x90, 0x01, 0, 0]);
      expect(VolcanoCodec.encodeTargetTemperature(230), [0xFC, 0x08, 0, 0]);
    });

    test('rejects values that do not fit', () {
      expect(
        () => VolcanoCodec.encodeTargetTemperature(39),
        throwsFormatException,
      );
      expect(
        () => VolcanoCodec.encodeTargetTemperature(231),
        throwsFormatException,
      );
    });
  });

  test('heater and pump commands are a single zero byte', () {
    expect(VolcanoCodec.command, [0x00]);
  });

  group('registers', () {
    test('register 1 decodes heater, auto shutdown and pump bits', () {
      final all = VolcanoRegister1Dto.decode([0x20, 0x22]);
      expect(all.heaterOn, isTrue);
      expect(all.autoShutdown, isTrue);
      expect(all.pumpOn, isTrue);

      final none = VolcanoRegister1Dto.decode([0x00, 0x00]);
      expect(none.heaterOn, isFalse);
      expect(none.autoShutdown, isFalse);
      expect(none.pumpOn, isFalse);

      final heaterOnly = VolcanoRegister1Dto.decode([0x20, 0x00, 0x00, 0x00]);
      expect(heaterOnly.heaterOn, isTrue);
      expect(heaterOnly.pumpOn, isFalse);
    });

    test('register 2: Fahrenheit is direct, display on cooling inverted', () {
      final cleared = VolcanoRegister2Dto.decode([0x00, 0x00]);
      expect(cleared.fahrenheit, isFalse);
      expect(cleared.displayOnCooling, isTrue);

      final set = VolcanoRegister2Dto.decode([0x00, 0x12]);
      expect(set.fahrenheit, isTrue);
      expect(set.displayOnCooling, isFalse);
    });

    test('register 3: vibration bit is inverted', () {
      expect(
        VolcanoRegister3Dto.decode([0x00, 0x00]).vibrationWhenReady,
        isTrue,
      );
      expect(
        VolcanoRegister3Dto.decode([0x00, 0x04]).vibrationWhenReady,
        isFalse,
      );
    });

    test('short register packets throw', () {
      expect(() => VolcanoRegister1Dto.decode([0x20]), throwsFormatException);
    });
  });

  group('VolcanoWriteSafety', () {
    test('allows exactly target, heater on/off and pump on/off', () {
      expect(VolcanoWriteSafety.allowed, {
        '10110003-5354-4f52-5a26-4249434b454c',
        '1011000f-5354-4f52-5a26-4249434b454c',
        '10110010-5354-4f52-5a26-4249434b454c',
        '10110013-5354-4f52-5a26-4249434b454c',
        '10110014-5354-4f52-5a26-4249434b454c',
      });
    });

    test('check throws for anything else', () {
      for (final uuid in [
        VolcanoUuids.register1,
        VolcanoUuids.register2,
        VolcanoUuids.register3,
        VolcanoUuids.currentTemperature,
        '10110005-5354-4f52-5a26-4249434b454c',
      ]) {
        expect(
          () => VolcanoWriteSafety.check(uuid),
          throwsA(isA<VolcanoWriteNotAllowedException>()),
        );
      }
      VolcanoWriteSafety.check(VolcanoUuids.targetTemperature);
    });
  });
}
