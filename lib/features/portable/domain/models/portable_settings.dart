class PortableSettings {
  const PortableSettings({
    required this.fahrenheit,
    required this.vibrateWhenReady,
    required this.ecoCharge,
    required this.ecoVoltage,
    required this.boostVisualisation,
  });

  final bool fahrenheit;
  final bool vibrateWhenReady;

  /// Charge limit.
  final bool ecoCharge;

  /// Battery saver.
  final bool ecoVoltage;

  /// Show boost state on the device LEDs.
  final bool boostVisualisation;

  PortableSettings copyWith({
    bool? fahrenheit,
    bool? vibrateWhenReady,
    bool? ecoCharge,
    bool? ecoVoltage,
    bool? boostVisualisation,
  }) => PortableSettings(
    fahrenheit: fahrenheit ?? this.fahrenheit,
    vibrateWhenReady: vibrateWhenReady ?? this.vibrateWhenReady,
    ecoCharge: ecoCharge ?? this.ecoCharge,
    ecoVoltage: ecoVoltage ?? this.ecoVoltage,
    boostVisualisation: boostVisualisation ?? this.boostVisualisation,
  );

  @override
  bool operator ==(Object other) =>
      other is PortableSettings &&
      other.fahrenheit == fahrenheit &&
      other.vibrateWhenReady == vibrateWhenReady &&
      other.ecoCharge == ecoCharge &&
      other.ecoVoltage == ecoVoltage &&
      other.boostVisualisation == boostVisualisation;

  @override
  int get hashCode => Object.hash(
    fahrenheit,
    vibrateWhenReady,
    ecoCharge,
    ecoVoltage,
    boostVisualisation,
  );
}
