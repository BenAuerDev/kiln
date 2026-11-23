/// Byte layouts of the Volcano Hybrid characteristics, as used by the
/// official web app v3.4.1 (see docs/protocol.md, Volcano Hybrid).
abstract final class VolcanoCodec {
  /// Heater and pump on/off characteristics trigger on a single zero byte.
  static const command = [0x00];

  /// Readings at or above this many tenths (6536 °C) are not real values.
  static const _invalidTenths = 65360;

  /// Decodes a temperature in °C from the first two bytes (uint16 LE, °C × 10).
  /// The characteristic may be longer; extra bytes are ignored.
  /// Returns `null` for readings the official app ignores (≥ 6536 °C).
  static double? decodeTemperature(List<int> bytes) {
    final tenths = _uint16(bytes, 'temperature');
    if (tenths >= _invalidTenths) return null;
    return tenths / 10;
  }

  /// Status registers are read as uint16 LE from the first two bytes.
  static int decodeRegister(List<int> bytes) => _uint16(bytes, 'register');

  /// Range the official app allows. A last line of defence: use cases clamp
  /// before they get here.
  static const minTargetCelsius = 40;
  static const maxTargetCelsius = 230;

  /// The target is written as uint32 LE, °C × 10, although it reads as uint16.
  static List<int> encodeTargetTemperature(int celsius) {
    if (celsius < minTargetCelsius || celsius > maxTargetCelsius) {
      throw FormatException('target out of range: $celsius');
    }
    final tenths = celsius * 10;
    return [tenths & 0xFF, (tenths >> 8) & 0xFF, 0x00, 0x00];
  }

  static int _uint16(List<int> bytes, String field) {
    if (bytes.length < 2) {
      throw FormatException('$field: expected 2 bytes, got ${bytes.length}');
    }
    return bytes[0] | (bytes[1] << 8);
  }
}
