import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/ramps/data/models/ramp_dto.dart';
import 'package:kiln/features/ramps/domain/models/ramp_profile.dart';
import 'package:kiln/features/ramps/domain/repositories/ramps_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_editing_service.dart';

import '../../mocks.dart';

void main() {
  late FakeRampsDataSource dataSource;
  late RampsRepository repository;

  const evening = RampProfile(
    id: 'user.1',
    name: 'Evening',
    startCelsius: 175,
    endCelsius: 200,
    stepCelsius: 5,
    interval: Duration(seconds: 90),
  );

  setUp(() {
    dataSource = FakeRampsDataSource([
      const RampDto(
        id: 'user.1',
        name: 'Evening',
        startCelsius: 175,
        endCelsius: 200,
        stepCelsius: 5,
        intervalSeconds: 90,
      ),
      // Out of range: brought into the limits on load.
      const RampDto(
        id: 'user.2',
        name: 'Odd',
        startCelsius: 300,
        endCelsius: 10,
        stepCelsius: 99,
        intervalSeconds: 1,
      ),
    ]);
    repository = RampsRepository(
      dataSource: dataSource,
      editing: RampEditingService(),
    );
  });

  test('loads the stored ramps within the limits', () async {
    expect(await repository.load(), right(unit));
    expect(repository.byId('user.1'), evening);
    final odd = repository.byId('user.2')!;
    expect([odd.startCelsius, odd.endCelsius, odd.stepCelsius], [209, 210, 25]);
    expect(odd.interval, const Duration(seconds: 15));
  });

  test('save inserts or replaces in place; delete removes', () async {
    await repository.load();
    await repository.save(evening.copyWith(name: 'Late'));
    await repository.save(evening.copyWith(id: 'user.3', name: 'New'));
    expect(repository.ramps.value.map((r) => r.name), ['Late', 'Odd', 'New']);
    expect(dataSource.stored.map((r) => r.name), ['Late', 'Odd', 'New']);

    await repository.delete('user.2');
    expect(repository.ramps.value.map((r) => r.id), ['user.1', 'user.3']);
    expect(dataSource.stored.map((r) => r.id), ['user.1', 'user.3']);
  });

  test('the chosen ramp: Classic, then stored and read back', () async {
    expect(repository.selectedId.value, 'preset.classic');
    expect(await repository.select('user.1'), right(unit));
    expect(dataSource.selected, 'user.1');

    final again = RampsRepository(
      dataSource: dataSource,
      editing: RampEditingService(),
    );
    await again.load();
    expect(again.selectedId.value, 'user.1');
  });

  test('a choice made before loading finished wins', () async {
    dataSource.selected = 'user.2';
    await repository.select('preset.quick');
    await repository.load();
    expect(repository.selectedId.value, 'preset.quick');
  });

  test('a failed choice write is a storage error, the choice stays', () async {
    dataSource.failWrites = true;
    expect(
      await repository.select('user.1'),
      left<AppError, Unit>(const AppError.storage()),
    );
    expect(repository.selectedId.value, 'user.1');
  });

  test('drops entries whose id was seen before', () async {
    dataSource.stored = [...dataSource.stored, dataSource.stored.first];
    await repository.load();
    expect(repository.ramps.value.map((r) => r.id), ['user.1', 'user.2']);
  });

  test('a failed load is a storage error', () async {
    dataSource.failReads = true;
    expect(
      await repository.load(),
      left<AppError, Unit>(const AppError.storage()),
    );
  });

  test(
    'writes only after a successful load, never over unread ramps',
    () async {
      dataSource.failReads = true;
      expect(
        await repository.save(evening.copyWith(id: 'user.3')),
        left<AppError, Unit>(const AppError.storage()),
      );
      expect(dataSource.writes, 0);
      expect(dataSource.stored, hasLength(2));

      dataSource.failReads = false;
      await repository.save(evening.copyWith(id: 'user.3'));
      expect(dataSource.stored.map((r) => r.id), [
        'user.1',
        'user.2',
        'user.3',
      ]);
    },
  );

  test('a failed write is a storage error and changes nothing', () async {
    await repository.load();
    dataSource.failWrites = true;
    expect(
      await repository.delete('user.1'),
      left<AppError, Unit>(const AppError.storage()),
    );
    expect(repository.ramps.value, hasLength(2));
  });
}
