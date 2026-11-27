import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/ramps/domain/models/ramp_field.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/ramps/data/models/ramp_dto.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/presentation/screens/ramp_editor_screen.dart';
import 'package:kiln/features/ramps/presentation/view_models/ramp_editor_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/presentation/widgets/portable_ramp_banner.dart';
import 'package:kiln/features/ramps/presentation/widgets/portable_ramp_card.dart';

import '../../../portable/helpers/portable_fixtures.dart' show testStatus;
import '../../../portable/presentation/pump_app.dart';
import '../../helpers/ramp_registration.dart';
import '../../mocks.dart';

class _MockEditor extends Mock implements RampEditorViewModel {}

void main() {
  tearDown(sl.reset);

  testWidgets('card shows the presets and Start', (tester) async {
    registerRamp(status: testStatus(heaterMode: HeaterMode.normal));
    await pumpKiln(tester, const PortableRampCard());
    expect(find.text('Gentle'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('180–200°'), findsOneWidget);
    expect(find.text('Start ramp'), findsOneWidget);
  });

  testWidgets('card lists user ramps; edit and New ramp navigate', (
    tester,
  ) async {
    final navigator = MockRampsNavigator();
    registerRamp(
      status: testStatus(heaterMode: HeaterMode.normal),
      navigator: navigator,
      ramps: fakeRampsRepository([
        const RampDto(
          id: 'user.1',
          name: 'Evening',
          startCelsius: 175,
          endCelsius: 195,
          stepCelsius: 5,
          intervalSeconds: 60,
        ),
      ]),
    );
    await pumpKiln(tester, const PortableRampCard());
    await tester.pump();

    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('175–195°'), findsOneWidget);
    await tester.tap(find.text('Evening'));
    await tester.pump();
    expect(find.text('+5° every 1 min · 4 min'), findsOneWidget);

    expect(find.bySemanticsLabel(RegExp('Edit Evening')), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.tap(find.bySemanticsLabel(RegExp('New ramp')));
    verify(() => navigator.openEditor(id: 'user.1')).called(1);
    verify(() => navigator.openEditor(from: 'user.1')).called(1);
  });

  testWidgets('editor shows the four values and saves', (tester) async {
    final vm = _stubEditor();
    sl.registerFactoryParam<RampEditorViewModel, String?, String?>(
      (_, _) => vm,
    );
    await pumpKiln(tester, const RampEditorScreen(fromId: 'preset.classic'));

    for (final text in ['New ramp', 'Start', 'End', 'Step', 'Every']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('180–200°'), findsOneWidget);
    expect(find.text('Delete ramp'), findsNothing);
    expect(find.bySemanticsLabel('Lower interval'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Raise end'));
    await tester.tap(find.text('Save'));
    verify(() => vm.raise(RampField.end)).called(1);
    verify(() => vm.save()).called(1);
  });

  testWidgets('editor: Delete only for a saved ramp, asks once', (
    tester,
  ) async {
    final vm = _stubEditor(existing: true, confirming: true);
    sl.registerFactoryParam<RampEditorViewModel, String?, String?>(
      (_, _) => vm,
    );
    await pumpKiln(tester, const RampEditorScreen(rampId: 'user.1'));

    expect(find.text('Edit ramp'), findsOneWidget);
    await tester.tap(find.text('Tap again to delete'));
    verify(() => vm.delete()).called(1);
  });

  testWidgets('banner only while a ramp runs', (tester) async {
    final runs = RampRunRepository()
      ..update(
        RampRun(
          profile: RampService.presets.first,
          deviceId: 'veazy-id',
          session: 1,
          target: 175,
          nextTarget: 180,
          nextStepAt: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );
    registerRamp(
      runs: runs,
      status: testStatus(heaterMode: HeaterMode.normal),
    );
    await pumpKiln(tester, const PortableRampBanner());
    expect(find.text('RAMP RUNNING'), findsOneWidget);
    expect(find.text('Stop ramp'), findsOneWidget);
  });
}

_MockEditor _stubEditor({bool existing = false, bool confirming = false}) {
  final vm = _MockEditor();
  Computed<T> value<T>(T v) => computed(() => v);
  when(() => vm.isExisting).thenReturn(value(existing));
  when(() => vm.canSave).thenReturn(value(true));
  when(() => vm.saving).thenReturn(signal(false));
  when(() => vm.name).thenReturn(signal(''));
  when(() => vm.draftVersion).thenReturn(signal(0));
  when(() => vm.confirmingDelete).thenReturn(signal(confirming));
  when(() => vm.maxNameLength).thenReturn(40);
  when(() => vm.range).thenReturn(value('180–200°'));
  when(() => vm.summary).thenReturn(value('+5° every 1 min 30 s · 6 min'));
  when(() => vm.stepCount).thenReturn(value('5 steps'));
  when(() => vm.startLabel).thenReturn(value('180°'));
  when(() => vm.endLabel).thenReturn(value('200°'));
  when(() => vm.stepLabel).thenReturn(value('+5°'));
  when(() => vm.intervalLabel).thenReturn(value('1:30'));
  when(() => vm.minutesUnit).thenReturn(value('min'));
  when(() => vm.save()).thenAnswer((_) async {});
  when(() => vm.delete()).thenAnswer((_) async {});
  return vm;
}
