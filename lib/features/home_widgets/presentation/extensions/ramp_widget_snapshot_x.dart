import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/presentation/extensions/device_finish_x.dart';
import '../../../ramps/presentation/extensions/ramp_profile_x.dart';
import '../../domain/models/ramp_widget_content.dart';
import '../../domain/models/ramp_widget_snapshot.dart';

extension RampWidgetSnapshotX on RampWidgetSnapshot {
  /// Ring with the base, the ramp's name, where it stands and Start/Stop.
  /// While a step counts down, Android ticks the countdown itself from
  /// [RampWidgetContent.nextStepAtMillis]. The widget is always dark, so
  /// the colours are the finish's dark ones.
  RampWidgetContent content(AppLocalizations l10n) {
    final accent = finish.tokens.dark;
    final name = profile.displayName(l10n);
    final next = nextTarget;
    final due = nextStepAt;
    return RampWidgetContent(
      name: name,
      center: l10n.homeWidgetTemperature(target),
      status: switch (phase) {
        RampWidgetPhase.idle => profile.summary(l10n, duration),
        // Counted like the bases the ramp writes, its start included.
        RampWidgetPhase.running => l10n.homeWidgetRampStep(step + 1, steps + 1),
        RampWidgetPhase.waitingForBoost => l10n.homeWidgetRampAfterBoost(
          next ?? target,
        ),
        RampWidgetPhase.finished => l10n.homeWidgetRampDone(target),
      },
      statusAccent: isRunning,
      countdownFormat: next != null && due != null
          ? l10n.homeWidgetRampNext(next)
          : '',
      nextStepAtMillis: due?.millisecondsSinceEpoch ?? 0,
      progress: steps == 0 ? 0 : (step / steps).clamp(0.0, 1.0),
      gaugeDescription: phase == RampWidgetPhase.idle
          ? l10n.homeWidgetRampGaugeIdle(name, target, profile.endCelsius)
          : l10n.homeWidgetRampGauge(name, step + 1, steps + 1, target),
      buttonLabel: isRunning
          ? l10n.homeWidgetRampStop
          : boosting
          ? l10n.homeWidgetRampNotWhileBoosting
          : l10n.homeWidgetRampStart,
      buttonActive: isRunning,
      offlineStatus: l10n.homeWidgetOffline,
      offlineButtonLabel: l10n.homeWidgetRampStart,
      accent: accent.accent.toARGB32(),
      accentText: accent.accentText.toARGB32(),
      onAccent: accent.onAccent.toARGB32(),
      gradientStart: accent.gradientStart.toARGB32(),
      gradientEnd: accent.gradientEnd.toARGB32(),
    );
  }
}
