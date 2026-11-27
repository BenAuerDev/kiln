import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/presentation/extensions/device_finish_x.dart';
import '../../../portable/domain/models/heater_mode.dart';
import '../../../portable/domain/models/portable_heat_phase.dart';
import '../../domain/models/portable_widget_content.dart';
import '../../domain/models/portable_widget_snapshot.dart';

extension PortableWidgetSnapshotX on PortableWidgetSnapshot {
  /// Battery ring with the device (red when low, a bolt by the % while
  /// charging), status, the base → boost → superboost
  /// ladder and Heat / Boost (the wide card of design/Widgets.dc.html, with
  /// the Veazy tile's values). A button that is on is filled with the
  /// accent and names what a tap does next, like the app's Boost button.
  /// The widget is always dark, so the colours are the finish's dark ones.
  PortableWidgetContent content(AppLocalizations l10n) {
    final accent = finish.tokens.dark;
    final heaterOn = heaterMode != HeaterMode.off;
    return PortableWidgetContent(
      glyph: model.name,
      name: model.displayName,
      battery: l10n.homeWidgetBattery(battery.percent),
      batteryLevel: (battery.percent / 100).clamp(0.0, 1.0),
      batteryLow: battery.low,
      charging: battery.charging,
      ringDescription: battery.charging
          ? l10n.homeWidgetPortableRingCharging(
              model.displayName,
              battery.percent,
            )
          : battery.low
          ? l10n.homeWidgetPortableRingLow(model.displayName, battery.percent)
          : l10n.homeWidgetPortableRing(model.displayName, battery.percent),
      offlineRingDescription: l10n.homeWidgetPortableRing(
        model.displayName,
        battery.percent,
      ),
      status: switch (phase) {
        PortableHeatPhase.off => l10n.homeWidgetHeaterOff(ladder.base),
        PortableHeatPhase.heating => l10n.homeWidgetHeating(activeTemperature),
        PortableHeatPhase.ready => l10n.homeWidgetReady(activeTemperature),
      },
      statusAccent: heaterOn,
      baseLabel: l10n.homeWidgetBase,
      base: l10n.homeWidgetTemperature(ladder.base),
      boostLabel: l10n.homeWidgetBoost,
      boost: l10n.homeWidgetTemperature(ladder.boostTemperature),
      superLabel: l10n.homeWidgetSuper,
      superBoost: l10n.homeWidgetTemperature(ladder.superBoostTemperature),
      basePosition: ladder.basePosition,
      boostPosition: ladder.boostPosition,
      superBoostPosition: ladder.superBoostPosition,
      ladderDescription: l10n.homeWidgetPortableLadder(
        ladder.base,
        ladder.boostTemperature,
        ladder.superBoostTemperature,
      ),
      heatLabel: heaterOn ? l10n.homeWidgetHeatOff : l10n.homeWidgetHeat,
      heatActive: heaterOn,
      boostButtonLabel: switch (heaterMode) {
        HeaterMode.off || HeaterMode.normal => l10n.homeWidgetBoost,
        HeaterMode.boost => l10n.homeWidgetSuperBoost,
        HeaterMode.superboost => l10n.homeWidgetBoostOff,
      },
      boostActive:
          heaterMode == HeaterMode.boost || heaterMode == HeaterMode.superboost,
      offlineStatus: l10n.homeWidgetOffline,
      offlineHeatLabel: l10n.homeWidgetHeat,
      offlineBoostLabel: l10n.homeWidgetBoost,
      accent: accent.accent.toARGB32(),
      accentText: accent.accentText.toARGB32(),
      onAccent: accent.onAccent.toARGB32(),
      gradientStart: accent.gradientStart.toARGB32(),
      gradientEnd: accent.gradientEnd.toARGB32(),
    );
  }
}
