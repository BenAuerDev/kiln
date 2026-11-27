/// Battery state of a Venty or Veazy.
class PortableBattery {
  const PortableBattery({required this.percent, required this.charging});

  /// At or below this, and not charging, the battery counts as [low].
  static const lowPercent = 15;

  final int percent;
  final bool charging;

  /// Nearly empty and not on the charger.
  bool get low => !charging && percent <= lowPercent;

  @override
  bool operator ==(Object other) =>
      other is PortableBattery &&
      other.percent == percent &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(percent, charging);
}
