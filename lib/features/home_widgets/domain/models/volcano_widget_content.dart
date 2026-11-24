/// The Volcano widget, ready to draw: texts in the app language and colours
/// as ARGB. It carries the offline texts too, because Android decides on
/// its own that kiln is gone (see `VolcanoWidgetProvider.kt`).
class VolcanoWidgetContent {
  const VolcanoWidgetContent({
    required this.name,
    required this.temperature,
    required this.status,
    required this.statusAccent,
    required this.progress,
    required this.gaugeDescription,
    required this.heatLabel,
    required this.heatActive,
    required this.airLabel,
    required this.airActive,
    required this.offlineTemperature,
    required this.offlineStatus,
    required this.offlineHeatLabel,
    required this.offlineAirLabel,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String name;
  final String temperature;
  final String status;

  /// [status] in the accent text colour (heating or ready) or muted.
  final bool statusAccent;

  /// Gauge arc, 0–1.
  final double progress;
  final String gaugeDescription;
  final String heatLabel;
  final bool heatActive;
  final String airLabel;
  final bool airActive;
  final String offlineTemperature;
  final String offlineStatus;
  final String offlineHeatLabel;
  final String offlineAirLabel;
  final int accent;
  final int accentText;
  final int onAccent;
  final int gradientStart;
  final int gradientEnd;

  @override
  bool operator ==(Object other) =>
      other is VolcanoWidgetContent &&
      other.name == name &&
      other.temperature == temperature &&
      other.status == status &&
      other.statusAccent == statusAccent &&
      other.progress == progress &&
      other.gaugeDescription == gaugeDescription &&
      other.heatLabel == heatLabel &&
      other.heatActive == heatActive &&
      other.airLabel == airLabel &&
      other.airActive == airActive &&
      other.offlineTemperature == offlineTemperature &&
      other.offlineStatus == offlineStatus &&
      other.offlineHeatLabel == offlineHeatLabel &&
      other.offlineAirLabel == offlineAirLabel &&
      other.accent == accent &&
      other.accentText == accentText &&
      other.onAccent == onAccent &&
      other.gradientStart == gradientStart &&
      other.gradientEnd == gradientEnd;

  @override
  int get hashCode => Object.hashAll([
    name,
    temperature,
    status,
    statusAccent,
    progress,
    gaugeDescription,
    heatLabel,
    heatActive,
    airLabel,
    airActive,
    offlineTemperature,
    offlineStatus,
    offlineHeatLabel,
    offlineAirLabel,
    accent,
    accentText,
    onAccent,
    gradientStart,
    gradientEnd,
  ]);
}
