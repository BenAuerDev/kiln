import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/data/models/portable_device_settings_dto.dart';

void main() {
  test('decodes brightness, vibration and boost timeout', () {
    final dto = PortableDeviceSettingsDto.decode(const [6, 0, 7, 0, 0, 1, 1]);

    expect(dto.brightness, 7);
    expect(dto.vibrationOn, isTrue);
    expect(dto.boostTimeoutDisabled, isTrue);
  });

  test('vibration 0 is off and byte 6 is optional', () {
    final dto = PortableDeviceSettingsDto.decode(const [6, 0, 5, 0, 0, 0]);

    expect(dto.vibrationOn, isFalse);
    expect(dto.boostTimeoutDisabled, isNull);
  });

  test('throws FormatException for short or foreign packets', () {
    expect(
      () => PortableDeviceSettingsDto.decode(const [6, 0, 5]),
      throwsFormatException,
    );
    expect(
      () => PortableDeviceSettingsDto.decode(const [1, 0, 5, 0, 0, 1, 0]),
      throwsFormatException,
    );
  });
}
