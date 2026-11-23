import 'heater_mode.dart';
import 'portable_settings.dart';

/// Live state of a Venty or Veazy. Temperatures are always °C, regardless of
/// the unit shown on the device.
class PortableStatus {
  const PortableStatus({
    required this.currentTemperature,
    required this.targetTemperature,
    required this.boostOffset,
    required this.superBoostOffset,
    required this.batteryPercent,
    required this.charging,
    required this.heaterMode,
    required this.autoOffSeconds,
    required this.settings,
    this.setpointReached = false,
  });

  /// `null` when the device reports no reading (`0x8000`).
  final double? currentTemperature;
  final int targetTemperature;
  final int boostOffset;
  final int superBoostOffset;
  final int batteryPercent;
  final bool charging;
  final HeaterMode heaterMode;
  final int autoOffSeconds;
  final PortableSettings settings;

  /// The heater has reached its setpoint (read-only device flag).
  final bool setpointReached;

  PortableStatus copyWith({
    double? currentTemperature,
    int? targetTemperature,
    int? boostOffset,
    int? superBoostOffset,
    int? batteryPercent,
    bool? charging,
    HeaterMode? heaterMode,
    int? autoOffSeconds,
    PortableSettings? settings,
    bool? setpointReached,
  }) => PortableStatus(
    currentTemperature: currentTemperature ?? this.currentTemperature,
    targetTemperature: targetTemperature ?? this.targetTemperature,
    boostOffset: boostOffset ?? this.boostOffset,
    superBoostOffset: superBoostOffset ?? this.superBoostOffset,
    batteryPercent: batteryPercent ?? this.batteryPercent,
    charging: charging ?? this.charging,
    heaterMode: heaterMode ?? this.heaterMode,
    autoOffSeconds: autoOffSeconds ?? this.autoOffSeconds,
    settings: settings ?? this.settings,
    setpointReached: setpointReached ?? this.setpointReached,
  );

  @override
  bool operator ==(Object other) =>
      other is PortableStatus &&
      other.currentTemperature == currentTemperature &&
      other.targetTemperature == targetTemperature &&
      other.boostOffset == boostOffset &&
      other.superBoostOffset == superBoostOffset &&
      other.batteryPercent == batteryPercent &&
      other.charging == charging &&
      other.heaterMode == heaterMode &&
      other.autoOffSeconds == autoOffSeconds &&
      other.settings == settings &&
      other.setpointReached == setpointReached;

  @override
  int get hashCode => Object.hash(
    currentTemperature,
    targetTemperature,
    boostOffset,
    superBoostOffset,
    batteryPercent,
    charging,
    heaterMode,
    autoOffSeconds,
    settings,
    setpointReached,
  );
}
