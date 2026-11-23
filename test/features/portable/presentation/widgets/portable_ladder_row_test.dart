import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/presentation/widgets/setup/portable_ladder_row.dart';
import 'package:kiln/features/portable/presentation/widgets/setup/portable_step_button.dart';
import 'package:obers_ui/obers_ui.dart';

import '../pump_app.dart';

void main() {
  Future<List<String>> pumpRow(
    WidgetTester tester, {
    bool enabled = true,
  }) async {
    final taps = <String>[];
    await pumpKiln(
      tester,
      Center(
        child: PortableLadderRow(
          icon: OiIcons.zap,
          name: 'Boost',
          hint: 'Double-click',
          value: '+15°',
          sub: '→ 195°',
          subAccent: true,
          lowerLabel: 'Lower boost',
          raiseLabel: 'Raise boost',
          onLower: () => taps.add('lower'),
          onRaise: () => taps.add('raise'),
          enabled: enabled,
        ),
      ),
    );
    return taps;
  }

  testWidgets('shows name, hint, value and sub line', (tester) async {
    await pumpRow(tester);

    for (final text in ['Boost', 'Double-click', '+15°', '→ 195°']) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('−/+ call their callbacks', (tester) async {
    final taps = await pumpRow(tester);

    await tester.tap(find.bySemanticsLabel('Lower boost'));
    await tester.tap(find.bySemanticsLabel('Raise boost'));
    await tester.tap(find.bySemanticsLabel('Raise boost'));

    expect(taps, ['lower', 'raise', 'raise']);
  });

  testWidgets('disabled buttons ignore taps', (tester) async {
    final taps = await pumpRow(tester, enabled: false);

    await tester.tap(find.bySemanticsLabel('Raise boost'));

    expect(taps, isEmpty);
  });

  testWidgets('buttons are 44×44', (tester) async {
    await pumpRow(tester);

    expect(
      tester.getSize(find.byType(PortableStepButton).first),
      const Size(44, 44),
    );
  });
}
