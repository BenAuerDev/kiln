import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/presentation/widgets/setup/portable_quick_setup_control.dart';

import '../pump_app.dart';

void main() {
  const options = [
    (name: 'Flavour', range: '175–195°'),
    (name: 'Balanced', range: '180–210°'),
    (name: 'Full', range: '190–210°'),
  ];

  Future<List<int>> pumpControl(WidgetTester tester, int? checked) async {
    final picks = <int>[];
    await pumpKiln(
      tester,
      Center(
        child: PortableQuickSetupControl(
          options: options,
          checkedIndex: checked,
          onSelect: picks.add,
          semanticLabel: 'Quick setups',
        ),
      ),
    );
    return picks;
  }

  void expectChecked(WidgetTester tester, String label, {required bool on}) =>
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(hasCheckedState: true, isChecked: on),
      );

  testWidgets('shows names and ranges and checks the matching one', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpControl(tester, 1);

    expect(find.text('Flavour'), findsOneWidget);
    expect(find.text('180–210°'), findsOneWidget);
    expectChecked(tester, 'Balanced, 180–210°', on: true);
    expectChecked(tester, 'Flavour, 175–195°', on: false);
    handle.dispose();
  });

  testWidgets('nothing is checked when no setup matches', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpControl(tester, null);

    for (final option in options) {
      expectChecked(tester, '${option.name}, ${option.range}', on: false);
    }
    handle.dispose();
  });

  testWidgets('tapping an option reports its index', (tester) async {
    final picks = await pumpControl(tester, null);

    await tester.tap(find.text('Full'));
    await tester.tap(find.text('Flavour'));

    expect(picks, [2, 0]);
  });
}
