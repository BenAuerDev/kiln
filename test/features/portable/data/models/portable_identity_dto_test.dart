import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/data/models/portable_identity_dto.dart';

void main() {
  test('reads the colour index from byte 18', () {
    final bytes = List<int>.filled(20, 0)
      ..[0] = 0x05
      ..[18] = 2;

    expect(PortableIdentityDto.decode(bytes).colorIndex, 2);
  });

  test('has no colour index when the reply is 18 bytes or shorter', () {
    final bytes = List<int>.filled(18, 0)..[0] = 0x05;

    expect(PortableIdentityDto.decode(bytes).colorIndex, isNull);
  });

  test('throws FormatException for empty or foreign packets', () {
    expect(() => PortableIdentityDto.decode(const []), throwsFormatException);
    expect(
      () => PortableIdentityDto.decode(const [1, 0, 0]),
      throwsFormatException,
    );
  });
}
