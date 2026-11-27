import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/features/portable/domain/models/portable_battery.dart';
import 'package:kiln/features/portable/presentation/widgets/common/portable_battery_indicator.dart';
import 'package:kiln/features/portable/presentation/widgets/common/portable_battery_painter.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../pump_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, PortableBattery battery) => pumpKiln(
    tester,
    Center(child: PortableBatteryIndicator(battery: battery)),
  );

  PortableBatteryPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(PortableBatteryIndicator),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as PortableBatteryPainter;

  Color? labelColor(WidgetTester tester) =>
      tester.widget<OiLabel>(find.byType(OiLabel)).color;

  testWidgets('fills to the level in the accent', (tester) async {
    await pump(tester, const PortableBattery(percent: 72, charging: false));

    expect(find.text('72%'), findsOneWidget);
    expect(find.bySemanticsLabel('72% battery'), findsOneWidget);
    final p = painter(tester);
    expect(p.level, 0.72);
    expect(p.charging, isFalse);
    expect(p.fill, KilnPalette.blue.dark.accent);
    expect(labelColor(tester), KilnPalette.darkSurfaces.muted);
  });

  testWidgets('turns red when low', (tester) async {
    await pump(tester, const PortableBattery(percent: 15, charging: false));

    expect(find.bySemanticsLabel('15% battery, low'), findsOneWidget);
    expect(painter(tester).fill, KilnPalette.darkSurfaces.low);
    expect(labelColor(tester), KilnPalette.darkSurfaces.low);
  });

  testWidgets('shows the bolt, not red, while charging', (tester) async {
    await pump(tester, const PortableBattery(percent: 8, charging: true));

    expect(find.bySemanticsLabel('8% · charging'), findsOneWidget);
    final p = painter(tester);
    expect(p.charging, isTrue);
    expect(p.fill, KilnPalette.blue.dark.accent);
    expect(labelColor(tester), KilnPalette.darkSurfaces.muted);
  });
}
