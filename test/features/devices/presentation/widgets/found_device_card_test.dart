import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/presentation/widgets/common/device_glyph.dart';
import 'package:kiln/features/devices/presentation/widgets/welcome/found_device_card.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_kiln.dart';

void main() {
  testWidgets('shows the model as plain text with a glyph and connects', (
    tester,
  ) async {
    var taps = 0;
    await pumpKiln(
      tester,
      FoundDeviceCard(
        device: discoveredVenty,
        connecting: false,
        onConnect: () => taps++,
      ),
    );

    expect(find.text('Venty'), findsOneWidget);
    expect(find.text('Signal strong'), findsOneWidget);
    expect(find.byType(DeviceGlyph), findsOneWidget);
    expect(find.bySemanticsLabel('Connect to Venty'), findsOneWidget);

    await tester.tap(find.text('Connect'));
    expect(taps, 1);
  });

  testWidgets('a disabled card does not connect', (tester) async {
    var taps = 0;
    await pumpKiln(
      tester,
      FoundDeviceCard(
        device: discoveredVenty,
        connecting: false,
        enabled: false,
        onConnect: () => taps++,
      ),
    );

    await tester.tap(find.text('Connect'), warnIfMissed: false);
    expect(taps, 0);
  });
}
