import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/ramps/domain/models/ramp_profile.dart';
import 'package:kiln/features/ramps/domain/repositories/ramps_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_editing_service.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/domain/use_cases/delete_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/find_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/load_ramps_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/save_ramp_use_case.dart';

import '../../mocks.dart';

void main() {
  late RampsRepository repository;
  late SaveRampUseCase save;
  late FindRampUseCase find;

  const draft = RampProfile(
    id: '',
    name: '  Evening  ',
    startCelsius: 175,
    endCelsius: 200,
    stepCelsius: 5,
    interval: Duration(seconds: 90),
  );

  setUp(() async {
    repository = fakeRampsRepository();
    await LoadRampsUseCase(repository: repository)();
    save = SaveRampUseCase(
      repository: repository,
      editing: RampEditingService(),
      clock: () => DateTime.fromMicrosecondsSinceEpoch(42),
    );
    find = FindRampUseCase(repository: repository);
  });

  group('save', () {
    test('a new ramp gets an id and a trimmed name', () async {
      final saved = (await save(draft)).getOrElse((_) => none()).toNullable();
      expect(saved?.id, 'user.42');
      expect(saved?.name, 'Evening');
      expect(saved?.isPreset, isFalse);
      expect(repository.byId('user.42'), saved);
    });

    test('an existing ramp keeps its id', () async {
      await save(draft.copyWith(id: 'user.7'));
      expect(repository.byId('user.7')?.name, 'Evening');
    });

    test('a copied preset becomes a new user ramp', () async {
      await save(RampService.presets.first.copyWith(name: 'Mine'));
      final [ramp] = repository.ramps.value;
      expect(ramp.id, 'user.42');
      expect(ramp.isPreset, isFalse);
    });

    test('values are brought into the limits', () async {
      await save(draft.copyWith(stepCelsius: 99, endCelsius: 300));
      final ramp = repository.byId('user.42')!;
      expect([ramp.stepCelsius, ramp.endCelsius], [25, 210]);
    });

    test('without a name nothing is saved', () async {
      expect(await save(draft.copyWith(name: ' ')), right(none()));
      expect(repository.ramps.value, isEmpty);
    });

    test('long names are cut to the limit', () async {
      await save(draft.copyWith(name: 'x' * 60));
      expect(
        repository.byId('user.42')!.name,
        hasLength(RampEditingService.maxNameLength),
      );
    });
  });

  test('find knows presets and user ramps, not deleted ones', () async {
    expect(find('preset.quick').toNullable(), RampService.presets[2]);
    await save(draft);
    expect(find('user.42').toNullable()?.name, 'Evening');
    await DeleteRampUseCase(repository: repository)('user.42');
    expect(find('user.42'), none());
  });
}
