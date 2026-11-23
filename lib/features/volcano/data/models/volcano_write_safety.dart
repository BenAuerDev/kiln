import 'volcano_uuids.dart';

/// Thrown before any BLE traffic when a write is not on the allow-list.
class VolcanoWriteNotAllowedException implements Exception {
  const VolcanoWriteNotAllowedException(this.characteristicUuid);

  final String characteristicUuid;

  @override
  String toString() => 'VolcanoWriteNotAllowedException: $characteristicUuid';
}

/// The only Volcano characteristics kiln may write. Each entry was checked
/// against the official web app (docs/protocol.md, Volcano Hybrid).
abstract final class VolcanoWriteSafety {
  static const allowed = {
    VolcanoUuids.targetTemperature,
    VolcanoUuids.heaterOn,
    VolcanoUuids.heaterOff,
    VolcanoUuids.pumpOn,
    VolcanoUuids.pumpOff,
  };

  static bool allows(String characteristicUuid) =>
      allowed.contains(characteristicUuid);

  /// Throws [VolcanoWriteNotAllowedException] for anything not on [allowed].
  static void check(String characteristicUuid) {
    if (!allows(characteristicUuid)) {
      throw VolcanoWriteNotAllowedException(characteristicUuid);
    }
  }
}
