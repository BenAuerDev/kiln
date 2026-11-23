import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/presentation/widgets/setup/portable_scale_bar.dart';
import 'package:kiln/features/portable/presentation/widgets/setup/portable_scale_marker.dart';

import '../pump_app.dart';

void main() {
  Widget bar({double base = 0.2, double boost = 0.5, double top = 1}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 39),
        child: Align(
          alignment: Alignment.topCenter,
          child: PortableScaleBar(
            basePosition: base,
            boostPosition: boost,
            superBoostPosition: top,
            minLabel: '40°',
            maxLabel: '210°',
            semanticLabel: 'Base 180 °C, boost 195 °C, superboost 210 °C',
          ),
        ),
      );

  /// Track starts at x = 39 + 6 and is 390 − 2·39 − 2·6 = 300 wide.
  const trackLeft = 45.0;
  const trackWidth = 300.0;

  double markerCentre(WidgetTester tester, int index) =>
      tester.getCenter(find.byType(PortableScaleMarker).at(index)).dx;

  testWidgets('places the three numbered markers on the scale', (tester) async {
    await pumpKiln(tester, bar());

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('40°'), findsOneWidget);
    expect(find.text('210°'), findsOneWidget);
    expect(markerCentre(tester, 0), closeTo(trackLeft + 0.2 * trackWidth, .5));
    expect(markerCentre(tester, 1), closeTo(trackLeft + 0.5 * trackWidth, .5));
    expect(markerCentre(tester, 2), closeTo(trackLeft + trackWidth, .5));
    expect(
      find.bySemanticsLabel('Base 180 °C, boost 195 °C, superboost 210 °C'),
      findsOneWidget,
    );
  });

  testWidgets('jumps without animation under reduced motion', (tester) async {
    await pumpKiln(tester, bar());
    await pumpKiln(tester, bar(base: 0.4));

    expect(markerCentre(tester, 0), closeTo(trackLeft + 0.4 * trackWidth, .5));
  });

  testWidgets('springs to a new position otherwise', (tester) async {
    await pumpKiln(tester, bar(), disableAnimations: false);
    await pumpKiln(tester, bar(base: 0.4), disableAnimations: false);

    final start = markerCentre(tester, 0);
    expect(start, lessThan(trackLeft + 0.4 * trackWidth));

    await tester.pumpAndSettle();
    expect(markerCentre(tester, 0), closeTo(trackLeft + 0.4 * trackWidth, .5));
  });
}
