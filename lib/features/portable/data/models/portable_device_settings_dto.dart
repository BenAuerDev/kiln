import 'portable_protocol.dart';

/// Raw content of a `0x06` reply (brightness, vibration, boost timeout).
class PortableDeviceSettingsDto {
  const PortableDeviceSettingsDto({
    required this.brightness,
    required this.vibrationOn,
    this.boostTimeoutDisabled,
  });

  /// Throws [FormatException] for packets shorter than 6 bytes or a wrong
  /// command byte.
  factory PortableDeviceSettingsDto.decode(List<int> bytes) {
    if (bytes.length < 6) {
      throw FormatException(
        'device settings packet too short: ${bytes.length} bytes',
        bytes,
      );
    }
    if (bytes[0] != PortableCommand.deviceSettings) {
      throw FormatException('not a device settings packet', bytes);
    }
    return PortableDeviceSettingsDto(
      brightness: bytes[2],
      vibrationOn: bytes[5] != 0,
      boostTimeoutDisabled: bytes.length >= 7 ? bytes[6] != 0 : null,
    );
  }

  /// 1–9.
  final int brightness;
  final bool vibrationOn;
  final bool? boostTimeoutDisabled;
}
