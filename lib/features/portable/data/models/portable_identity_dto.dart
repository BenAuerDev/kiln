import 'portable_protocol.dart';

/// Raw content of a `0x05` reply. kiln only needs the Veazy colour index.
class PortableIdentityDto {
  const PortableIdentityDto({required this.colorIndex});

  /// Throws [FormatException] for an empty packet or a wrong command byte.
  factory PortableIdentityDto.decode(List<int> bytes) {
    if (bytes.isEmpty || bytes[0] != PortableCommand.identity) {
      throw FormatException('not an identity packet', bytes);
    }
    return PortableIdentityDto(
      colorIndex: bytes.length > _colorIndexByte
          ? bytes[_colorIndexByte]
          : null,
    );
  }

  /// The official app reads this on the Veazy only, and only when the reply
  /// is longer than 18 bytes. What a Venty sends here is unverified.
  static const _colorIndexByte = 18;

  final int? colorIndex;
}
