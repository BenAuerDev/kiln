import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/volcano/domain/extensions/volcano_status_x.dart';
import 'package:kiln/features/volcano/domain/models/volcano_heat_phase.dart';

import '../../mocks.dart';

void main() {
  group('phase', () {
    test('off when the heater is off', () {
      expect(
        sampleStatus.copyWith(heaterOn: false).phase,
        VolcanoHeatPhase.off,
      );
    });

    test('heating below the target', () {
      expect(sampleStatus.phase, VolcanoHeatPhase.heating);
    });

    test('ready within half a degree of the target', () {
      expect(
        sampleStatus.copyWith(currentTemperature: 184.5).phase,
        VolcanoHeatPhase.ready,
      );
      expect(
        sampleStatus.copyWith(currentTemperature: 190).phase,
        VolcanoHeatPhase.ready,
      );
    });
  });

  test('fractions map 40–230 °C to 0–1 and clamp', () {
    expect(sampleStatus.copyWith(targetTemperature: 40).targetFraction, 0);
    expect(sampleStatus.copyWith(targetTemperature: 230).targetFraction, 1);
    expect(sampleStatus.copyWith(targetTemperature: 135).targetFraction, 0.5);
    expect(sampleStatus.copyWith(currentTemperature: 20).currentFraction, 0);
  });
}
