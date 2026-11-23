import '../models/device_finish.dart';

/// Maps the body colour a device reports to a finish.
class FinishDetectionService {
  const FinishDetectionService();

  /// Byte 18 of the Venty/Veazy identity reply (command `0x05`). The official
  /// web app reads it on the Veazy only and maps 2 blue, 3 pink, 4 orange and
  /// everything else to black. No source documents a Volcano Onyx flag, so
  /// lava is never detected.
  DeviceFinish fromVeazyColorIndex(int index) => switch (index) {
    2 => DeviceFinish.blue,
    3 => DeviceFinish.pink,
    4 => DeviceFinish.ember,
    _ => DeviceFinish.mono,
  };
}
