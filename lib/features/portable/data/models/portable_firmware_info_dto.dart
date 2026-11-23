import 'portable_protocol.dart';

/// Raw content of a `0x02` reply. kiln only needs the firmware flags.
class PortableFirmwareInfoDto {
  const PortableFirmwareInfoDto({required this.flags});

  /// Throws [FormatException] for packets shorter than 2 bytes or a wrong
  /// command byte.
  factory PortableFirmwareInfoDto.decode(List<int> bytes) {
    if (bytes.length < 2) {
      throw FormatException(
        'firmware info packet too short: ${bytes.length} bytes',
        bytes,
      );
    }
    if (bytes[0] != PortableCommand.firmwareInfo) {
      throw FormatException('not a firmware info packet', bytes);
    }
    return PortableFirmwareInfoDto(flags: bytes[1]);
  }

  final int flags;

  /// `false` means the device is in bootloader mode: send nothing else.
  bool get applicationRunning =>
      flags & PortableFirmwareFlag.applicationRunning != 0;
}
