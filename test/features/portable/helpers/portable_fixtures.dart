import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_settings.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/repositories/portable_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPortableRepository extends Mock implements PortableRepository {}

const testSettings = PortableSettings(
  fahrenheit: false,
  vibrateWhenReady: true,
  ecoCharge: false,
  ecoVoltage: false,
  boostVisualisation: true,
);

PortableStatus testStatus({
  int target = 180,
  int boost = 15,
  int superBoost = 15,
  HeaterMode heaterMode = HeaterMode.off,
  PortableSettings settings = testSettings,
}) => PortableStatus(
  currentTemperature: null,
  targetTemperature: target,
  boostOffset: boost,
  superBoostOffset: superBoost,
  batteryPercent: 80,
  charging: false,
  heaterMode: heaterMode,
  autoOffSeconds: 0,
  settings: settings,
);

/// A 20-byte `0x01` status notification.
List<int> statusPacket({
  int currentTenths = 0x8000,
  int targetTenths = 1800,
  int boost = 15,
  int superBoost = 15,
  int battery = 80,
  int autoOffLow = 0,
  int autoOffHigh = 0,
  int heaterMode = 0,
  int charger = 0,
  int settings = 0,
  int settings2 = 0,
  int length = 20,
}) {
  final bytes = List<int>.filled(20, 0)
    ..[0] = 0x01
    ..[2] = currentTenths & 0xFF
    ..[3] = currentTenths >> 8
    ..[4] = targetTenths & 0xFF
    ..[5] = targetTenths >> 8
    ..[6] = boost
    ..[7] = superBoost
    ..[8] = battery
    ..[9] = autoOffLow
    ..[10] = autoOffHigh
    ..[11] = heaterMode
    ..[13] = charger
    ..[14] = settings
    ..[16] = settings2;
  return bytes.sublist(0, length);
}

/// `0x02` reply with the given firmware flags (`0x01` = application running).
List<int> firmwareReply({int flags = 0x01}) => [
  0x02,
  flags,
  ...'V01.11'.codeUnits,
  ...List<int>.filled(12, 0),
];

/// `0x06` reply.
List<int> deviceSettingsReply({bool vibration = true}) => [
  0x06,
  0x00,
  0x05,
  0x00,
  0x00,
  if (vibration) 0x01 else 0x00,
  0x00,
];

/// Builds a zero-filled packet of [length] bytes with [values] at the given
/// indices, for byte-exact comparisons.
List<int> packet(Map<int, int> values, {int length = 20}) {
  final bytes = List<int>.filled(length, 0);
  values.forEach((index, value) => bytes[index] = value);
  return bytes;
}
