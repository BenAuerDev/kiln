/// The three temperatures of the "set it once" ladder and their positions on
/// the 40–210 °C scale.
class PortableLadder {
  const PortableLadder({
    required this.base,
    required this.boostTemperature,
    required this.superBoostTemperature,
    required this.basePosition,
    required this.boostPosition,
    required this.superBoostPosition,
    required this.boostAtMax,
    required this.superBoostAtMax,
  });

  final int base;

  /// `base + boost offset`, capped at the device maximum.
  final int boostTemperature;

  /// `boost temperature + superboost offset`, capped at the device maximum.
  final int superBoostTemperature;

  /// 0…1 on the 40–210 °C scale.
  final double basePosition;
  final double boostPosition;
  final double superBoostPosition;
  final bool boostAtMax;
  final bool superBoostAtMax;

  @override
  bool operator ==(Object other) =>
      other is PortableLadder &&
      other.base == base &&
      other.boostTemperature == boostTemperature &&
      other.superBoostTemperature == superBoostTemperature &&
      other.basePosition == basePosition &&
      other.boostPosition == boostPosition &&
      other.superBoostPosition == superBoostPosition &&
      other.boostAtMax == boostAtMax &&
      other.superBoostAtMax == superBoostAtMax;

  @override
  int get hashCode => Object.hash(
    base,
    boostTemperature,
    superBoostTemperature,
    basePosition,
    boostPosition,
    superBoostPosition,
    boostAtMax,
    superBoostAtMax,
  );
}
