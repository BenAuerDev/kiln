import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_ladder.dart';
import 'package:kiln/features/portable/domain/models/quick_setup.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  final service = PortableLadderService();

  group('ladder', () {
    test('stacks boost and superboost on the base', () {
      final ladder = service.ladder(
        testStatus(target: 180, boost: 15, superBoost: 10),
      );

      expect(
        ladder,
        const PortableLadder(
          base: 180,
          boostTemperature: 195,
          superBoostTemperature: 205,
          basePosition: 140 / 170,
          boostPosition: 155 / 170,
          superBoostPosition: 165 / 170,
          boostAtMax: false,
          superBoostAtMax: false,
        ),
      );
    });

    test('caps superboost at 210 °C', () {
      final ladder = service.ladder(
        testStatus(target: 195, boost: 10, superBoost: 15),
      );

      expect(ladder.boostTemperature, 205);
      expect(ladder.superBoostTemperature, 210);
      expect(ladder.boostAtMax, isFalse);
      expect(ladder.superBoostAtMax, isTrue);
      expect(ladder.superBoostPosition, 1.0);
    });

    test('caps boost and superboost at 210 °C', () {
      final ladder = service.ladder(
        testStatus(target: 205, boost: 10, superBoost: 10),
      );

      expect(ladder.boostTemperature, 210);
      expect(ladder.superBoostTemperature, 210);
      expect(ladder.boostAtMax, isTrue);
      expect(ladder.superBoostAtMax, isTrue);
    });

    test('positions start at 0 for 40 °C', () {
      final ladder = service.ladder(
        testStatus(target: 40, boost: 1, superBoost: 1),
      );

      expect(ladder.basePosition, 0.0);
      expect(ladder.boostPosition, closeTo(1 / 170, 1e-9));
    });

    test('positions stay within 0…1 for device values outside the range', () {
      final ladder = service.ladder(
        testStatus(target: 30, boost: 5, superBoost: 5),
      );

      expect(ladder.basePosition, 0.0);
      expect(ladder.boostPosition, 0.0);
    });
  });

  group('active target', () {
    test('base while off or normal', () {
      for (final mode in [HeaterMode.off, HeaterMode.normal]) {
        final status = testStatus(heaterMode: mode);
        expect(service.activeTemperature(status), 180);
        expect(service.activePosition(status), closeTo(140 / 170, 1e-9));
      }
    });

    test('boost temperature in boost', () {
      final status = testStatus(heaterMode: HeaterMode.boost);
      expect(service.activeTemperature(status), 195);
      expect(service.activePosition(status), closeTo(155 / 170, 1e-9));
    });

    test('superboost temperature, capped, in superboost', () {
      final status = testStatus(heaterMode: HeaterMode.superboost);
      expect(service.activeTemperature(status), 210);
      expect(service.activePosition(status), 1);
    });
  });

  group('quickSetupLadder', () {
    test('stacks the quick setup values', () {
      final ladder = service.quickSetupLadder(QuickSetup.flavour);
      expect(ladder.base, 175);
      expect(ladder.boostTemperature, 185);
      expect(ladder.superBoostTemperature, 195);
      expect(ladder.superBoostAtMax, isFalse);
    });

    test('tops out at 210 °C', () {
      for (final setup in [QuickSetup.balanced, QuickSetup.full]) {
        final ladder = service.quickSetupLadder(setup);
        expect(ladder.superBoostTemperature, 210);
        expect(ladder.superBoostAtMax, isTrue);
      }
    });
  });

  group('matchingQuickSetup', () {
    test('finds each quick setup', () {
      expect(
        service.matchingQuickSetup(
          testStatus(target: 175, boost: 10, superBoost: 10),
        ),
        QuickSetup.flavour,
      );
      expect(
        service.matchingQuickSetup(
          testStatus(target: 180, boost: 15, superBoost: 15),
        ),
        QuickSetup.balanced,
      );
      expect(
        service.matchingQuickSetup(
          testStatus(target: 190, boost: 10, superBoost: 10),
        ),
        QuickSetup.full,
      );
    });

    test('returns null for custom values', () {
      expect(
        service.matchingQuickSetup(
          testStatus(target: 180, boost: 15, superBoost: 14),
        ),
        isNull,
      );
    });
  });
}
