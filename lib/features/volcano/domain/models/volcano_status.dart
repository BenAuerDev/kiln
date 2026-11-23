/// Live state of a Volcano Hybrid. Temperatures are always °C.
class VolcanoStatus {
  const VolcanoStatus({
    required this.currentTemperature,
    required this.targetTemperature,
    required this.heaterOn,
    required this.pumpOn,
    required this.autoShutdown,
    required this.fahrenheit,
    required this.displayOnCooling,
    required this.vibrationWhenReady,
  });

  /// `null` until the device reports a valid reading.
  final double? currentTemperature;
  final int targetTemperature;
  final bool heaterOn;
  final bool pumpOn;
  final bool autoShutdown;
  final bool fahrenheit;
  final bool displayOnCooling;
  final bool vibrationWhenReady;

  VolcanoStatus copyWith({
    double? currentTemperature,
    int? targetTemperature,
    bool? heaterOn,
    bool? pumpOn,
    bool? autoShutdown,
    bool? fahrenheit,
    bool? displayOnCooling,
    bool? vibrationWhenReady,
  }) => VolcanoStatus(
    currentTemperature: currentTemperature ?? this.currentTemperature,
    targetTemperature: targetTemperature ?? this.targetTemperature,
    heaterOn: heaterOn ?? this.heaterOn,
    pumpOn: pumpOn ?? this.pumpOn,
    autoShutdown: autoShutdown ?? this.autoShutdown,
    fahrenheit: fahrenheit ?? this.fahrenheit,
    displayOnCooling: displayOnCooling ?? this.displayOnCooling,
    vibrationWhenReady: vibrationWhenReady ?? this.vibrationWhenReady,
  );

  @override
  bool operator ==(Object other) =>
      other is VolcanoStatus &&
      other.currentTemperature == currentTemperature &&
      other.targetTemperature == targetTemperature &&
      other.heaterOn == heaterOn &&
      other.pumpOn == pumpOn &&
      other.autoShutdown == autoShutdown &&
      other.fahrenheit == fahrenheit &&
      other.displayOnCooling == displayOnCooling &&
      other.vibrationWhenReady == vibrationWhenReady;

  @override
  int get hashCode => Object.hash(
    currentTemperature,
    targetTemperature,
    heaterOn,
    pumpOn,
    autoShutdown,
    fahrenheit,
    displayOnCooling,
    vibrationWhenReady,
  );
}
