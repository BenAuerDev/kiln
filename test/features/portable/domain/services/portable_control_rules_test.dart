import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/domain/services/portable_control_rules.dart';
import 'package:kiln/features/portable/domain/services/portable_temperature_limits.dart';

void main() {
  test('presets lie within the limits, ascending', () {
    const presets = PortableControlRules.presets;
    for (final preset in presets) {
      expect(PortableTemperatureLimits.clampTemperature(preset), preset);
    }
    expect([...presets]..sort(), presets);
  });
}
