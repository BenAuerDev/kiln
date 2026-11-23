import 'portable_protocol.dart';

/// Builders for every packet kiln writes to a Venty/Veazy.
///
/// Each `0x01` write is 20 bytes, zeroed except for the bytes it fills, and
/// sets only the mask bits for those bytes (a mask bit with a zero byte
/// would write 0 to that field).
abstract final class PortablePackets {
  static const packetLength = 20;
  static const deviceSettingsPacketLength = 7;

  /// Range the official web app allows for target writes.
  static const minTargetCelsius = 40;
  static const maxTargetCelsius = 210;

  /// Range the official web app allows for boost/superboost offset writes.
  static const minOffset = 1;
  static const maxOffset = 99;

  /// `01 00 00…`: status request (mask 0, writes nothing).
  static List<int> statusPoll() => _packet(PortableCommand.status);

  /// `02 00…`: firmware info request, used to detect bootloader mode.
  static List<int> firmwareInfoRequest() =>
      _packet(PortableCommand.firmwareInfo);

  /// `05 00…`: identity request (serial, Veazy colour).
  static List<int> identityRequest() => _packet(PortableCommand.identity);

  /// `06 00 00 00 00 00 00`: read brightness / vibration / boost timeout.
  static List<int> deviceSettingsRead() =>
      List<int>.filled(deviceSettingsPacketLength, 0)
        ..[0] = PortableCommand.deviceSettings;

  /// `01 02 00 00 LL HH 00…`: target °C × 10, uint16 LE.
  static List<int> targetTemperature(int celsius) {
    RangeError.checkValueInInterval(
      celsius,
      minTargetCelsius,
      maxTargetCelsius,
      'celsius',
    );
    final tenths = celsius * 10;
    return _packet(PortableCommand.status, PortableWriteMask.targetTemperature)
      ..[4] = tenths & 0xFF
      ..[5] = (tenths >> 8) & 0xFF;
  }

  /// `01 04 … [6]=offset`.
  static List<int> boostOffset(int offset) {
    RangeError.checkValueInInterval(offset, minOffset, maxOffset, 'offset');
    return _packet(PortableCommand.status, PortableWriteMask.boostOffset)
      ..[6] = offset;
  }

  /// `01 08 … [7]=offset`.
  static List<int> superBoostOffset(int offset) {
    RangeError.checkValueInInterval(offset, minOffset, maxOffset, 'offset');
    return _packet(PortableCommand.status, PortableWriteMask.superBoostOffset)
      ..[7] = offset;
  }

  /// `01 20 … [11]=1/0`. Only normal heating and off are verified; boost and
  /// superboost (2/3) are never built.
  static List<int> heater({required bool on}) => _heaterMode(
    on ? PortableHeaterModeCode.normal : PortableHeaterModeCode.off,
  );

  /// `01 20 … [11]=02`: verified on a Veazy and a Venty (not sent by the
  /// official app).
  static List<int> heaterBoost() => _heaterMode(PortableHeaterModeCode.boost);

  static List<int> _heaterMode(int code) =>
      _packet(PortableCommand.status, PortableWriteMask.heater)..[11] = code;

  /// `01 80 … [14]=value [15]=bit`: changes exactly one settings bit.
  static List<int> setting(
    PortableWritableSetting setting, {
    required bool set,
  }) => _packet(PortableCommand.status, PortableWriteMask.settings)
    ..[14] = set ? setting.bit : 0
    ..[15] = setting.bit;

  /// `06 08 00 00 00 01/00 00`: vibration when ready.
  static List<int> vibration({required bool on}) =>
      List<int>.filled(deviceSettingsPacketLength, 0)
        ..[0] = PortableCommand.deviceSettings
        ..[1] = PortableDeviceSettingsMask.vibration
        ..[5] = on ? 1 : 0;

  /// `0D 01 00…`: find my device.
  static List<int> findDevice() => _packet(PortableCommand.findDevice, 0x01);

  static List<int> _packet(int command, [int byte1 = 0]) =>
      List<int>.filled(packetLength, 0)
        ..[0] = command
        ..[1] = byte1;
}
