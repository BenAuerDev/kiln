import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/presentation/extensions/device_finish_x.dart';
import '../../../volcano/domain/models/volcano_heat_phase.dart';
import '../../domain/models/volcano_widget_content.dart';
import '../../domain/models/volcano_widget_snapshot.dart';

extension VolcanoWidgetSnapshotX on VolcanoWidgetSnapshot {
  /// Gauge, `Heating to 185°` and the Heat / Air buttons
  /// (design/Widgets.dc.html). A button that is on is filled with the
  /// accent and names what a tap does (`Heat off`). The widget is always
  /// dark, so the colours are the finish's dark ones.
  VolcanoWidgetContent content(AppLocalizations l10n) {
    final name = DeviceModel.volcanoHybrid.displayName;
    final current = temperature;
    final accent = finish.tokens.dark;
    return VolcanoWidgetContent(
      name: name,
      temperature: current == null
          ? l10n.homeWidgetNoTemperature
          : l10n.homeWidgetTemperature(current),
      status: switch (phase) {
        VolcanoHeatPhase.off => l10n.homeWidgetHeaterOff(target),
        VolcanoHeatPhase.heating => l10n.homeWidgetHeating(target),
        VolcanoHeatPhase.ready => l10n.homeWidgetReady(target),
      },
      statusAccent: heaterOn,
      progress: progress,
      gaugeDescription: current == null
          ? l10n.homeWidgetVolcanoGaugeNoReading(name)
          : l10n.homeWidgetVolcanoGauge(name, current, target),
      heatLabel: heaterOn ? l10n.homeWidgetHeatOff : l10n.homeWidgetHeat,
      heatActive: heaterOn,
      airLabel: pumpOn ? l10n.homeWidgetAirOff : l10n.homeWidgetAir,
      airActive: pumpOn,
      offlineTemperature: l10n.homeWidgetNoTemperature,
      offlineStatus: l10n.homeWidgetOffline,
      offlineHeatLabel: l10n.homeWidgetHeat,
      offlineAirLabel: l10n.homeWidgetAir,
      accent: accent.accent.toARGB32(),
      accentText: accent.accentText.toARGB32(),
      onAccent: accent.onAccent.toARGB32(),
      gradientStart: accent.gradientStart.toARGB32(),
      gradientEnd: accent.gradientEnd.toARGB32(),
    );
  }
}
