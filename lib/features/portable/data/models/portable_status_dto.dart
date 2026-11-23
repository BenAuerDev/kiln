import 'portable_protocol.dart';

/// Raw content of a `0x01` status notification.
class PortableStatusDto {
  const PortableStatusDto({
    required this.currentTemperatureTenths,
    required this.targetTemperatureTenths,
    required this.boostOffset,
    required this.superBoostOffset,
    required this.batteryPercent,
    required this.autoOffSeconds,
    required this.heaterModeCode,
    required this.chargerConnected,
    required this.settingsBits,
    this.settings2Bits,
  });

  /// Decodes a status notification (docs/protocol.md, Status packet).
  ///
  /// Throws [FormatException] for packets shorter than 15 bytes, a wrong
  /// command byte or an unknown heater mode.
  factory PortableStatusDto.decode(List<int> bytes) {
    if (bytes.length < minLength) {
      throw FormatException(
        'status packet too short: ${bytes.length} bytes',
        bytes,
      );
    }
    if (bytes[0] != PortableCommand.status) {
      throw FormatException('not a status packet: 0x${_hex(bytes[0])}', bytes);
    }
    final heaterMode = bytes[11];
    if (heaterMode > PortableHeaterModeCode.superBoost) {
      throw FormatException('unknown heater mode $heaterMode', bytes);
    }
    final current = _uint16(bytes, 2);
    return PortableStatusDto(
      // 0x8000 = "no reading" (third-party observation; the official app
      // hides this value for Venty/Veazy).
      currentTemperatureTenths: current >= noReading ? null : current,
      targetTemperatureTenths: _uint16(bytes, 4),
      boostOffset: bytes[6],
      superBoostOffset: bytes[7],
      batteryPercent: bytes[8],
      // The official app sums bytes 9 and 10 instead of reading a uint16.
      // Whether that is a quirk or the real layout is not verified.
      autoOffSeconds: bytes[9] + bytes[10],
      heaterModeCode: heaterMode,
      chargerConnected: bytes[13] != 0,
      settingsBits: bytes[14],
      settings2Bits: bytes.length >= 17 ? bytes[16] : null,
    );
  }

  static const minLength = 15;
  static const noReading = 0x8000;

  /// `null` when the device reports no reading.
  final int? currentTemperatureTenths;
  final int targetTemperatureTenths;
  final int boostOffset;
  final int superBoostOffset;
  final int batteryPercent;
  final int autoOffSeconds;

  /// See [PortableHeaterModeCode].
  final int heaterModeCode;
  final bool chargerConnected;

  /// See [PortableSettingsBit].
  final int settingsBits;

  /// See [PortableSettings2Bit]. Only present when the packet has ≥ 17 bytes.
  final int? settings2Bits;

  bool hasSetting(int bit) => settingsBits & bit != 0;

  static int _uint16(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  static String _hex(int value) => value.toRadixString(16).padLeft(2, '0');
}
