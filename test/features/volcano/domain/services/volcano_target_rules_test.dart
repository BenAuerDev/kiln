import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/volcano/domain/services/volcano_target_rules.dart';

void main() {
  test('clamp keeps 40–230 °C', () {
    expect(VolcanoTargetRules.clamp(39), 40);
    expect(VolcanoTargetRules.clamp(40), 40);
    expect(VolcanoTargetRules.clamp(185), 185);
    expect(VolcanoTargetRules.clamp(230), 230);
    expect(VolcanoTargetRules.clamp(231), 230);
  });

  test('next returns the clamped value or none() if unchanged', () {
    expect(VolcanoTargetRules.next(current: 185, requested: 186), some(186));
    expect(VolcanoTargetRules.next(current: 185, requested: 185), none<int>());
    expect(VolcanoTargetRules.next(current: 230, requested: 250), none<int>());
    expect(VolcanoTargetRules.next(current: 200, requested: 250), some(230));
  });

  test('presets lie within the limits', () {
    for (final preset in VolcanoTargetRules.presets) {
      expect(VolcanoTargetRules.clamp(preset), preset);
    }
  });
}
