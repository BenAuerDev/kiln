import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/services/welcome_gate.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('closed before the welcome without devices', () {
    expect(WelcomeGate.isPast(welcomeCompleted: false, devices: []), isFalse);
  });

  test('open once the welcome is completed', () {
    expect(WelcomeGate.isPast(welcomeCompleted: true, devices: []), isTrue);
  });

  test('open while any device is known', () {
    expect(
      WelcomeGate.isPast(welcomeCompleted: false, devices: const [veazy]),
      isTrue,
    );
  });
}
