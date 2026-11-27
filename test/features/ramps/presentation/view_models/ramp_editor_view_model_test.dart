import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/ramps/domain/models/ramp_field.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/ramps/data/models/ramp_dto.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/repositories/ramps_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_editing_service.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/domain/use_cases/delete_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/find_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/load_ramps_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/save_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/select_ramp_use_case.dart';
import 'package:kiln/features/ramps/presentation/view_models/ramp_editor_view_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late RampsRepository repository;
  late RampRunRepository runs;
  late MockRampsNavigator navigator;
  late MockToastService toast;
  late MockHapticsService haptics;

  setUpAll(() => registerFallbackValue(ToastLevel.info));

  setUp(() {
    repository = fakeRampsRepository([
      const RampDto(
        id: 'user.1',
        name: 'Evening',
        startCelsius: 175,
        endCelsius: 195,
        stepCelsius: 5,
        intervalSeconds: 60,
      ),
    ]);
    runs = RampRunRepository();
    navigator = MockRampsNavigator();
    toast = MockToastService();
    haptics = MockHapticsService();
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
  });

  RampEditorViewModel editor({String? id, String? from}) {
    final editing = RampEditingService();
    return RampEditorViewModel(
      rampId: id,
      fromId: from,
      findRamp: FindRampUseCase(repository: repository),
      loadRamps: LoadRampsUseCase(repository: repository),
      saveRamp: SaveRampUseCase(
        repository: repository,
        editing: editing,
        clock: () => DateTime.fromMicrosecondsSinceEpoch(9),
      ),
      deleteRamp: DeleteRampUseCase(repository: repository),
      selectRamp: SelectRampUseCase(repository: repository),
      editing: editing,
      ramps: const RampService(),
      runs: runs,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      navigator: navigator,
    );
  }

  test('a new ramp starts from the given preset, unnamed', () async {
    final vm = editor(from: 'preset.gentle');
    await pumpEventQueue();
    expect(vm.isExisting.value, isFalse);
    expect(vm.name.value, '');
    expect(vm.range.value, '170–190°');
    expect(vm.summary.value, '+5° every 2 min · 8 min');
    expect(vm.stepCount.value, '4 steps');
    expect(vm.canSave.value, isFalse);
    vm.setName('Mine');
    expect(vm.canSave.value, isTrue);
  });

  test('saving a new ramp chooses it and goes back', () async {
    final vm = editor(from: 'preset.classic');
    await pumpEventQueue();
    vm
      ..setName('Mine')
      ..raise(RampField.end)
      ..lower(RampField.interval);
    expect(vm.endLabel.value, '205°');
    expect(vm.intervalLabel.value, '1:15');
    await vm.save();
    final saved = repository.byId('user.9')!;
    expect(saved.name, 'Mine');
    expect([saved.startCelsius, saved.endCelsius], [180, 205]);
    expect(repository.selectedId.value, 'user.9');
    verify(() => navigator.back()).called(1);
    verify(() => toast.show('Ramp saved', level: ToastLevel.success)).called(1);
  });

  test('editing keeps the id; delete needs a second tap', () async {
    final vm = editor(id: 'user.1');
    await pumpEventQueue();
    expect(vm.isExisting.value, isTrue);
    expect(vm.name.value, 'Evening');
    expect(vm.startLabel.value, '175°');
    vm.raise(RampField.step);
    expect(vm.stepLabel.value, '+6°');
    await vm.save();
    expect(repository.ramps.value.single.stepCelsius, 6);

    await vm.delete();
    expect(vm.confirmingDelete.value, isTrue);
    expect(repository.ramps.value, hasLength(1));
    await vm.delete();
    expect(repository.ramps.value, isEmpty);
    verify(() => navigator.back()).called(2);
  });

  test('a preset id is copied into a new ramp, not edited', () async {
    final vm = editor(id: 'preset.quick');
    await pumpEventQueue();
    expect(vm.isExisting.value, isFalse);
    expect(vm.range.value, '185–205°');
    expect(vm.name.value, '');
  });

  test('a new ramp from a user ramp waits for loading', () async {
    final vm = editor(from: 'user.1');
    await pumpEventQueue();
    expect(vm.range.value, '175–195°');
    expect(vm.isExisting.value, isFalse);
  });

  test('saving while a ramp runs keeps the running choice', () async {
    runs.update(
      RampRun(
        profile: RampService.defaultPreset,
        deviceId: 'v',
        session: 1,
        target: 180,
        nextTarget: 185,
        nextStepAt: DateTime(2026),
      ),
    );
    final vm = editor();
    await pumpEventQueue();
    vm.setName('Mine');
    await vm.save();
    expect(repository.byId('user.9'), isNotNull);
    expect(repository.selectedId.value, RampService.defaultPreset.id);
  });
}
