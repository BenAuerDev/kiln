import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/domain/models/quick_setup.dart';

void main() {
  test('Flavour is 175 / +10 / +10', () {
    expect(QuickSetup.flavour.base, 175);
    expect(QuickSetup.flavour.boost, 10);
    expect(QuickSetup.flavour.superBoost, 10);
  });

  test('Balanced is 180 / +15 / +15', () {
    expect(QuickSetup.balanced.base, 180);
    expect(QuickSetup.balanced.boost, 15);
    expect(QuickSetup.balanced.superBoost, 15);
  });

  test('Full is 190 / +10 / +10', () {
    expect(QuickSetup.full.base, 190);
    expect(QuickSetup.full.boost, 10);
    expect(QuickSetup.full.superBoost, 10);
  });
}
