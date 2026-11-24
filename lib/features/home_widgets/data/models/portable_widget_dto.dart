/// Stored form of the Venty/Veazy widget, read by `PortableWidgetProvider.kt`.
/// Colours are ARGB, positions and the battery level 0–1.
class PortableWidgetDto {
  const PortableWidgetDto({
    required this.glyph,
    required this.name,
    required this.battery,
    required this.batteryLevel,
    required this.ringDescription,
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

  final String glyph;
  final String name;
  final String battery;
  final double batteryLevel;
  final String ringDescription;
  final String status;
  final bool statusAccent;
  final String baseLabel;
  final String base;
  final String boostLabel;
  final String boost;
  final String superLabel;
  final String superBoost;
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

  Map<String, Object?> toJson() => {
    'glyph': glyph,
    'name': name,
    'battery': battery,
    'batteryLevel': batteryLevel,
    'ringDescription': ringDescription,
    'status': status,
    'statusAccent': statusAccent,
    'baseLabel': baseLabel,
    'base': base,
    'boostLabel': boostLabel,
    'boost': boost,
    'superLabel': superLabel,
    'superBoost': superBoost,
    'basePosition': basePosition,
    'boostPosition': boostPosition,
    'superBoostPosition': superBoostPosition,
    'ladderDescription': ladderDescription,
    'heatLabel': heatLabel,
    'heatActive': heatActive,
    'boostButtonLabel': boostButtonLabel,
    'boostActive': boostActive,
    'offlineStatus': offlineStatus,
    'offlineHeatLabel': offlineHeatLabel,
    'offlineBoostLabel': offlineBoostLabel,
    'accent': accent,
    'accentText': accentText,
    'onAccent': onAccent,
    'gradientStart': gradientStart,
    'gradientEnd': gradientEnd,
  };
}
