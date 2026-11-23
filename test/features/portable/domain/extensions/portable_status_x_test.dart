import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/domain/extensions/portable_status_x.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_battery.dart';
import 'package:kiln/features/portable/domain/models/portable_heat_phase.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  group('heatPhase', () {
    test('off while the heater is off', () {
      expect(
        testStatus().copyWith(setpointReached: true).heatPhase,
        PortableHeatPhase.off,
      );
    });

    test('heating until the setpoint is reached', () {
      expect(
        testStatus(heaterMode: HeaterMode.normal).heatPhase,
        PortableHeatPhase.heating,
      );
    });

    test('ready once the setpoint is reached, boost included', () {
      for (final mode in [
        HeaterMode.normal,
        HeaterMode.boost,
        HeaterMode.superboost,
      ]) {
        expect(
          testStatus(
            heaterMode: mode,
          ).copyWith(setpointReached: true).heatPhase,
          PortableHeatPhase.ready,
        );
      }
    });
  });

  test('boostActive in boost and superboost only', () {
    expect(testStatus().boostActive, isFalse);
    expect(testStatus(heaterMode: HeaterMode.normal).boostActive, isFalse);
    expect(testStatus(heaterMode: HeaterMode.boost).boostActive, isTrue);
    expect(testStatus(heaterMode: HeaterMode.superboost).boostActive, isTrue);
  });

  test('battery', () {
    expect(
      testStatus().copyWith(batteryPercent: 72, charging: true).battery,
      const PortableBattery(percent: 72, charging: true),
    );
  });

  group('currentPosition', () {
    test('null without a reading', () {
      expect(testStatus().currentPosition, isNull);
    });

    test('maps 40–210 °C to 0–1', () {
      expect(testStatus().copyWith(currentTemperature: 40).currentPosition, 0);
      expect(
        testStatus().copyWith(currentTemperature: 125).currentPosition,
        closeTo(0.5, 1e-9),
      );
      expect(testStatus().copyWith(currentTemperature: 210).currentPosition, 1);
    });

    test('stays within 0–1 outside the range', () {
      expect(testStatus().copyWith(currentTemperature: 20).currentPosition, 0);
      expect(testStatus().copyWith(currentTemperature: 230).currentPosition, 1);
    });
  });

  group('gaugeProgress', () {
    test('follows a live reading', () {
      expect(
        testStatus(
          heaterMode: HeaterMode.normal,
        ).copyWith(currentTemperature: 125).gaugeProgress(0.8),
        closeTo(0.5, 1e-9),
      );
    });

    test('empty while heating without a reading', () {
      expect(testStatus(heaterMode: HeaterMode.normal).gaugeProgress(0.8), 0);
    });

    test('up to the target once ready without a reading', () {
      expect(
        testStatus(
          heaterMode: HeaterMode.normal,
        ).copyWith(setpointReached: true).gaugeProgress(0.8),
        0.8,
      );
    });
  });
}
