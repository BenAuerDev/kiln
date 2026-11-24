/// Stored form of the Volcano widget, read by `VolcanoWidgetProvider.kt`.
/// Colours are ARGB.
class VolcanoWidgetDto {
  const VolcanoWidgetDto({
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
  final bool statusAccent;
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

  Map<String, Object?> toJson() => {
    'name': name,
    'temperature': temperature,
    'status': status,
    'statusAccent': statusAccent,
    'progress': progress,
    'gaugeDescription': gaugeDescription,
    'heatLabel': heatLabel,
    'heatActive': heatActive,
    'airLabel': airLabel,
    'airActive': airActive,
    'offlineTemperature': offlineTemperature,
    'offlineStatus': offlineStatus,
    'offlineHeatLabel': offlineHeatLabel,
    'offlineAirLabel': offlineAirLabel,
    'accent': accent,
    'accentText': accentText,
    'onAccent': onAccent,
    'gradientStart': gradientStart,
    'gradientEnd': gradientEnd,
  };
}
