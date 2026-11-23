import '../models/device_finish.dart';
import '../models/finish_preference.dart';
import '../models/known_device.dart';

extension KnownDeviceX on KnownDevice {
  DeviceFinish get effectiveFinish => switch (finishPreference) {
    FixedFinish(:final finish) => finish,
    MatchDevice() => detectedFinish ?? DeviceFinish.ember,
  };

  /// Calendar days between the last connection and [now], or `null` if kiln
  /// never connected to it.
  int? daysSinceLastUse(DateTime now) {
    final last = lastConnectedAt;
    if (last == null) return null;
    final lastDay = DateTime.utc(last.year, last.month, last.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final days = today.difference(lastDay).inDays;
    return days < 0 ? 0 : days;
  }
}
