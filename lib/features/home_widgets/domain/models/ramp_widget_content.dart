/// The ramp widget, ready to draw: texts in the app language, colours as
/// ARGB, the next step as epoch milliseconds for Android's countdown. It
/// carries the offline texts too (see `RampWidgetProvider.kt`).
class RampWidgetContent {
  const RampWidgetContent({
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

  /// The ramp's name.
  final String name;

  /// The base in the ring: `185°`.
  final String center;
  final String status;
  final bool statusAccent;

  /// `190° in %s`, where Android puts the ticking countdown; empty when no
  /// step is counting down.
  final String countdownFormat;

  /// When the next step is due; 0 without a countdown.
  final int nextStepAtMillis;

  /// Ring arc, 0–1: steps written of all steps.
  final double progress;
  final String gaugeDescription;
  final String buttonLabel;

  /// Filled with the accent while a ramp runs (the button stops it).
  final bool buttonActive;
  final String offlineStatus;
  final String offlineButtonLabel;
  final int accent;
  final int accentText;
  final int onAccent;
  final int gradientStart;
  final int gradientEnd;

  List<Object> get _fields => [
    name,
    center,
    status,
    statusAccent,
    countdownFormat,
    nextStepAtMillis,
    progress,
    gaugeDescription,
    buttonLabel,
    buttonActive,
    offlineStatus,
    offlineButtonLabel,
    accent,
    accentText,
    onAccent,
    gradientStart,
    gradientEnd,
  ];

  @override
  bool operator ==(Object other) {
    if (other is! RampWidgetContent) return false;
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
