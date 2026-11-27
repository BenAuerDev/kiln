import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/home_widgets/domain/models/portable_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/domain/models/volcano_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/presentation/extensions/portable_widget_snapshot_x.dart';
import 'package:kiln/features/home_widgets/presentation/extensions/volcano_widget_snapshot_x.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_battery.dart';
import 'package:kiln/features/portable/domain/models/portable_heat_phase.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/volcano/domain/models/volcano_heat_phase.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';

import '../../portable/helpers/portable_fixtures.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  group('portable', () {
    PortableWidgetSnapshot snapshot({
      HeaterMode mode = HeaterMode.normal,
      PortableHeatPhase phase = PortableHeatPhase.heating,
      int active = 180,
      PortableBattery battery = const PortableBattery(
        percent: 72,
        charging: false,
      ),
    }) => PortableWidgetSnapshot(
      model: DeviceModel.veazy,
      battery: battery,
      ladder: PortableLadderService().ladder(testStatus(target: 180)),
      heaterMode: mode,
      phase: phase,
      activeTemperature: active,
      finish: DeviceFinish.blue,
    );

    test('a nearly empty battery is low until it charges', () {
      final low = snapshot(
        battery: const PortableBattery(percent: 12, charging: false),
      ).content(en);
      expect(low.batteryLow, isTrue);
      expect(low.charging, isFalse);
      expect(low.ringDescription, 'Veazy, battery 12%, low');
      expect(low.offlineRingDescription, 'Veazy, battery 12%');

      final charging = snapshot(
        battery: const PortableBattery(percent: 12, charging: true),
      ).content(en);
      expect(charging.batteryLow, isFalse);
      expect(charging.charging, isTrue);
      expect(charging.ringDescription, 'Veazy, battery 12%, charging');
      expect(charging.offlineRingDescription, 'Veazy, battery 12%');
    });

    test('device, battery ring, ladder and the dark blue finish', () {
      final content = snapshot().content(en);
      expect(content.glyph, 'veazy');
      expect(content.name, 'Veazy');
      expect(content.battery, '72%');
      expect(content.batteryLevel, 0.72);
      expect(content.ringDescription, 'Veazy, battery 72%');
      expect(content.batteryLow, isFalse);
      expect(content.charging, isFalse);
      expect(
        [content.baseLabel, content.boostLabel, content.superLabel],
        ['Base', 'Boost', 'Super'],
      );
      expect(
        [content.base, content.boost, content.superBoost],
        ['180°', '195°', '210°'],
      );
      // (180 − 40) / 170, (195 − 40) / 170, at the maximum.
      expect(content.basePosition, closeTo(0.824, 0.001));
      expect(content.boostPosition, closeTo(0.912, 0.001));
      expect(content.superBoostPosition, 1);
      expect(
        content.ladderDescription,
        'Base 180°, boost 195°, superboost 210°',
      );
      final blue = KilnPalette.blue.dark;
      expect(content.accent, blue.accent.toARGB32());
      expect(content.accentText, blue.accentText.toARGB32());
      expect(content.onAccent, blue.onAccent.toARGB32());
      expect(content.gradientStart, blue.gradientStart.toARGB32());
      expect(content.gradientEnd, blue.gradientEnd.toARGB32());
    });

    test('heater off: muted status with the base, nothing filled', () {
      final content = snapshot(
        mode: HeaterMode.off,
        phase: PortableHeatPhase.off,
      ).content(en);
      expect(content.status, 'Heater off · 180°');
      expect(content.statusAccent, isFalse);
      expect(content.heatLabel, 'Heat');
      expect(content.heatActive, isFalse);
      expect(content.boostButtonLabel, 'Boost');
      expect(content.boostActive, isFalse);
    });

    test('heating at base: Heat off filled, Boost next', () {
      final content = snapshot().content(en);
      expect(content.status, 'Heating to 180°');
      expect(content.statusAccent, isTrue);
      expect(content.heatLabel, 'Heat off');
      expect(content.heatActive, isTrue);
      expect(content.boostButtonLabel, 'Boost');
      expect(content.boostActive, isFalse);
    });

    test('Boost names the next step, like the app button', () {
      final boost = snapshot(
        mode: HeaterMode.boost,
        phase: PortableHeatPhase.ready,
        active: 195,
      ).content(en);
      expect(boost.status, 'Ready at 195°');
      expect(boost.boostButtonLabel, 'Superboost');
      expect(boost.boostActive, isTrue);

      final superBoost = snapshot(
        mode: HeaterMode.superboost,
        active: 210,
      ).content(en);
      expect(superBoost.status, 'Heating to 210°');
      expect(superBoost.boostButtonLabel, 'Boost off');
      expect(superBoost.boostActive, isTrue);
    });

    test('offline texts, and German', () {
      final content = snapshot().content(en);
      expect(content.offlineStatus, 'Not connected');
      expect(content.offlineHeatLabel, 'Heat');
      expect(content.offlineBoostLabel, 'Boost');
      final german = snapshot().content(de);
      expect(german.battery, '72 %');
      expect(german.baseLabel, 'Basis');
      expect(german.status, 'Heizt auf 180°');
      expect(german.ringDescription, 'Veazy, Akku 72 %');
    });
  });

  group('volcano', () {
    VolcanoWidgetSnapshot snapshot({
      int? temperature = 142,
      VolcanoHeatPhase phase = VolcanoHeatPhase.heating,
      bool pumpOn = false,
    }) => VolcanoWidgetSnapshot(
      temperature: temperature,
      target: 185,
      phase: phase,
      pumpOn: pumpOn,
      progress: 0.54,
      finish: DeviceFinish.ember,
    );

    test('heating: accent status, Heat off filled', () {
      final content = snapshot().content(en);
      expect(content.name, 'Volcano Hybrid');
      expect(content.temperature, '142°');
      expect(content.status, 'Heating to 185°');
      expect(content.statusAccent, isTrue);
      expect(content.progress, 0.54);
      expect(content.gaugeDescription, 'Volcano Hybrid at 142 of 185 degrees');
      expect(content.heatLabel, 'Heat off');
      expect(content.heatActive, isTrue);
      expect(content.airLabel, 'Air');
      expect(content.airActive, isFalse);
      final ember = KilnPalette.ember.dark;
      expect(content.accent, ember.accent.toARGB32());
      expect(content.accentText, ember.accentText.toARGB32());
      expect(content.onAccent, ember.onAccent.toARGB32());
      expect(content.gradientStart, ember.gradientStart.toARGB32());
      expect(content.gradientEnd, ember.gradientEnd.toARGB32());
    });

    test('ready, and air on', () {
      final content = snapshot(
        phase: VolcanoHeatPhase.ready,
        pumpOn: true,
      ).content(en);
      expect(content.status, 'Ready at 185°');
      expect(content.airLabel, 'Air off');
      expect(content.airActive, isTrue);
    });

    test('heater off: muted status, Heat not filled', () {
      final content = snapshot(phase: VolcanoHeatPhase.off).content(en);
      expect(content.status, 'Heater off · 185°');
      expect(content.statusAccent, isFalse);
      expect(content.heatLabel, 'Heat');
      expect(content.heatActive, isFalse);
    });

    test('no reading yet, and the offline texts', () {
      final content = snapshot(temperature: null).content(en);
      expect(content.temperature, '–');
      expect(content.gaugeDescription, 'Volcano Hybrid, no temperature yet');
      expect(content.offlineTemperature, '–');
      expect(content.offlineStatus, 'Not connected');
      expect(content.offlineHeatLabel, 'Heat');
      expect(content.offlineAirLabel, 'Air');
    });

    test('in German', () {
      final content = snapshot().content(de);
      expect(content.status, 'Heizt auf 185°');
      expect(content.heatLabel, 'Heizung aus');
      expect(content.offlineStatus, 'Nicht verbunden');
    });
  });
}
