/// The Venty/Veazy widget, ready to draw: texts in the app language and
/// colours as ARGB. It carries the offline texts too, because Android
/// decides on its own that kiln is gone (see `PortableWidgetProvider.kt`).
class PortableWidgetContent {
  const PortableWidgetContent({
    required this.glyph,
    required this.name,
    required this.battery,
    required this.batteryLevel,
    required this.batteryLow,
    required this.charging,
    required this.ringDescription,
    required this.offlineRingDescription,
    required this.status,
    required this.statusAccent,
    required this.baseLabel,
    required this.base,
    required this.boostLabel,
    required this.boost,
    required this.superLabel,
    required this.superBoost,
    required this.basePosition,
    required this.boostPosition,
    required this.superBoostPosition,
    required this.ladderDescription,
    required this.heatLabel,
    required this.heatActive,
    required this.boostButtonLabel,
    required this.boostActive,
    required this.offlineStatus,
    required this.offlineHeatLabel,
    required this.offlineBoostLabel,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.gradientStart,
    required this.gradientEnd,
  });

  /// `venty` or `veazy`: which line drawing the battery ring holds.
  final String glyph;
  final String name;
  final String battery;

  /// Battery ring arc, 0–1.
  final double batteryLevel;

  /// Ring and % in red: nearly empty, not charging.
  final bool batteryLow;

  /// A bolt next to the %.
  final bool charging;
  final String ringDescription;

  /// Without "low" or "charging": offline the ring is grey and the
  /// bolt hidden, as those may be stale.
  final String offlineRingDescription;
  final String status;
  final bool statusAccent;
  final String baseLabel;
  final String base;
  final String boostLabel;
  final String boost;
  final String superLabel;
  final String superBoost;

  /// Ladder bar positions on the 40–210 °C scale, 0–1.
  final double basePosition;
  final double boostPosition;
  final double superBoostPosition;
  final String ladderDescription;
  final String heatLabel;
  final bool heatActive;
  final String boostButtonLabel;
  final bool boostActive;
  final String offlineStatus;
  final String offlineHeatLabel;
  final String offlineBoostLabel;
  final int accent;
  final int accentText;
  final int onAccent;
  final int gradientStart;
  final int gradientEnd;

  List<Object> get _fields => [
    glyph,
    name,
    battery,
    batteryLevel,
    batteryLow,
    charging,
    ringDescription,
    offlineRingDescription,
    status,
    statusAccent,
    baseLabel,
    base,
    boostLabel,
    boost,
    superLabel,
    superBoost,
    basePosition,
    boostPosition,
    superBoostPosition,
    ladderDescription,
    heatLabel,
    heatActive,
    boostButtonLabel,
    boostActive,
    offlineStatus,
    offlineHeatLabel,
    offlineBoostLabel,
    accent,
    accentText,
    onAccent,
    gradientStart,
    gradientEnd,
  ];

  @override
  bool operator ==(Object other) {
    if (other is! PortableWidgetContent) return false;
    final a = _fields;
    final b = other._fields;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_fields);
}
