import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../workflows/presentation/extensions/workflow_run_x.dart';
import '../../../workflows/presentation/extensions/workflow_x.dart';
import '../../domain/models/background_notice.dart';
import '../../domain/models/heat_session.dart';

extension HeatSessionX on HeatSession {
  /// The ongoing notification: `Volcano Hybrid · 172°` / `Heating to 185°`,
  /// the workflow step while one runs, battery on portables.
  BackgroundNotice notice(AppLocalizations l10n) {
    final run = workflow;
    final phase = ready
        ? l10n.backgroundReady(target)
        : l10n.backgroundHeating(target);
    final battery = batteryPercent;
    final text = run != null
        ? l10n.backgroundWorkflow(
            run.workflow.displayName(l10n),
            run.headline(l10n),
          )
        : battery != null
        ? l10n.backgroundWithBattery(phase, battery)
        : phase;
    return _notice(
      l10n,
      l10n.backgroundTitle(model.displayName, temperature),
      text,
    );
  }

  /// `Veazy is ready · 180°` / `Double-click for boost 195°`.
  BackgroundNotice readyNotice(AppLocalizations l10n) {
    final boost = boostTarget;
    final text = model == DeviceModel.volcanoHybrid
        ? l10n.backgroundReadyVolcano
        : boost != null
        ? l10n.backgroundReadyBoost(boost)
        : l10n.backgroundReadyPlain;
    return _notice(
      l10n,
      l10n.backgroundReadyTitle(model.displayName, temperature),
      text,
    );
  }

  BackgroundNotice _notice(AppLocalizations l10n, String title, String text) =>
      BackgroundNotice(
        title: title,
        text: text,
        sessionChannel: l10n.backgroundChannelSession,
        readyChannel: l10n.backgroundChannelReady,
      );
}
