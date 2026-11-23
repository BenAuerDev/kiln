import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/data/models/portable_firmware_info_dto.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  test('application flag set means the application is running', () {
    expect(
      PortableFirmwareInfoDto.decode(firmwareReply()).applicationRunning,
      isTrue,
    );
  });

  test('application flag clear means bootloader mode', () {
    // 0x10 = invalid application, application bit clear.
    expect(
      PortableFirmwareInfoDto.decode(
        firmwareReply(flags: 0x10),
      ).applicationRunning,
      isFalse,
    );
  });

  test('throws FormatException for short or foreign packets', () {
    expect(
      () => PortableFirmwareInfoDto.decode(const [2]),
      throwsFormatException,
    );
    expect(
      () => PortableFirmwareInfoDto.decode(const [1, 1]),
      throwsFormatException,
    );
  });
}
