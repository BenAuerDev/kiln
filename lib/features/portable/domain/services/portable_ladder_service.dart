import 'dart:math' as math;

import '../models/heater_mode.dart';
import '../models/portable_ladder.dart';
import '../models/portable_status.dart';
import '../models/quick_setup.dart';
import 'portable_temperature_limits.dart';

/// Pure calculations for the base → boost → superboost ladder.
class PortableLadderService {
  static const _min = PortableTemperatureLimits.minTemperature;
  static const _max = PortableTemperatureLimits.maxTemperature;

  PortableLadder ladder(PortableStatus status) => _ladder(
    base: status.targetTemperature,
    boostOffset: status.boostOffset,
    superBoostOffset: status.superBoostOffset,
  );

  /// The ladder [setup] would write.
  PortableLadder quickSetupLadder(QuickSetup setup) => _ladder(
    base: setup.base,
    boostOffset: setup.boost,
    superBoostOffset: setup.superBoost,
  );

  /// The temperature the heater aims for in its current mode, boost included.
  int activeTemperature(PortableStatus status) {
    final ladder = this.ladder(status);
    return switch (status.heaterMode) {
      HeaterMode.off || HeaterMode.normal => ladder.base,
      HeaterMode.boost => ladder.boostTemperature,
      HeaterMode.superboost => ladder.superBoostTemperature,
    };
  }

  /// Scale position (0–1) of [activeTemperature].
  double activePosition(PortableStatus status) {
    final ladder = this.ladder(status);
    return switch (status.heaterMode) {
      HeaterMode.off || HeaterMode.normal => ladder.basePosition,
      HeaterMode.boost => ladder.boostPosition,
      HeaterMode.superboost => ladder.superBoostPosition,
    };
  }

  /// The quick setup whose three values match the device exactly, if any.
  QuickSetup? matchingQuickSetup(PortableStatus status) =>
      QuickSetup.values.where((setup) {
        return setup.base == status.targetTemperature &&
            setup.boost == status.boostOffset &&
            setup.superBoost == status.superBoostOffset;
      }).firstOrNull;

  PortableLadder _ladder({
    required int base,
    required int boostOffset,
    required int superBoostOffset,
  }) {
    final cappedBase = math.min(_max, base);
    final boost = math.min(_max, cappedBase + boostOffset);
    final superBoost = math.min(_max, boost + superBoostOffset);
    return PortableLadder(
      base: cappedBase,
      boostTemperature: boost,
      superBoostTemperature: superBoost,
      basePosition: _position(cappedBase),
      boostPosition: _position(boost),
      superBoostPosition: _position(superBoost),
      boostAtMax: boost == _max,
      superBoostAtMax: superBoost == _max,
    );
  }

  double _position(int celsius) =>
      ((celsius - _min) / (_max - _min)).clamp(0.0, 1.0);
}
