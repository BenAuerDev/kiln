import '../../../../core/formatters/duration_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/ramp_run.dart';

extension RampRunX on RampRun {
  /// `Now 185° · 190° in 0:42`, `… after boost`, or `Ramp done · 200°`.
  /// Empty for a stopped ramp.
  String statusLine(AppLocalizations l10n, DateTime now) {
    final next = nextTarget;
    return switch (phase) {
      RampRunPhase.finished => l10n.rampsFinished(target),
      RampRunPhase.stopped => '',
      RampRunPhase.running when next == null => l10n.rampsFinished(target),
      RampRunPhase.running when waitingForBoost => l10n.rampsWaitingForBoost(
        target,
        next!,
      ),
      RampRunPhase.running => l10n.rampsNow(
        target,
        next!,
        DurationFormatter.clock(nextStepAt.difference(now)),
      ),
    };
  }
}
