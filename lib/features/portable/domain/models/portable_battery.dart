/// Battery state of a Venty or Veazy.
class PortableBattery {
  const PortableBattery({required this.percent, required this.charging});

  final int percent;
  final bool charging;

  @override
  bool operator ==(Object other) =>
      other is PortableBattery &&
      other.percent == percent &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(percent, charging);
}
