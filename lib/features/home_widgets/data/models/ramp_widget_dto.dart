/// Stored form of the ramp widget, read by `RampWidgetProvider.kt`.
/// Colours are ARGB, the progress 0–1, the next step in epoch milliseconds.
class RampWidgetDto {
  const RampWidgetDto({
    required this.name,
    required this.center,
    required this.status,
    required this.statusAccent,
    required this.countdownFormat,
    required this.nextStepAtMillis,
    required this.progress,
    required this.gaugeDescription,
    required this.buttonLabel,
    required this.buttonActive,
    required this.offlineStatus,
    required this.offlineButtonLabel,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String name;
  final String center;
  final String status;
  final bool statusAccent;
  final String countdownFormat;
  final int nextStepAtMillis;
  final double progress;
  final String gaugeDescription;
  final String buttonLabel;
  final bool buttonActive;
  final String offlineStatus;
  final String offlineButtonLabel;
  final int accent;
  final int accentText;
  final int onAccent;
  final int gradientStart;
  final int gradientEnd;

  Map<String, Object?> toJson() => {
    'name': name,
    'center': center,
    'status': status,
    'statusAccent': statusAccent,
    'countdownFormat': countdownFormat,
    'nextStepAtMillis': nextStepAtMillis,
    'progress': progress,
    'gaugeDescription': gaugeDescription,
    'buttonLabel': buttonLabel,
    'buttonActive': buttonActive,
    'offlineStatus': offlineStatus,
    'offlineButtonLabel': offlineButtonLabel,
    'accent': accent,
    'accentText': accentText,
    'onAccent': onAccent,
    'gradientStart': gradientStart,
    'gradientEnd': gradientEnd,
  };
}
