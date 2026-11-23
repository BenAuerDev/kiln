import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/data/models/known_device_dto.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/finish_preference.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/repositories/known_devices_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockKnownDevicesDataSource dataSource;
  late MockConnectionRepository connection;
  late Signal<String?> activeId;
  late KnownDevicesRepository repository;

  setUpAll(() => registerFallbackValue(<KnownDeviceDto>[]));

  setUp(() {
    dataSource = MockKnownDevicesDataSource();
    connection = MockConnectionRepository();
    activeId = signal<String?>(null);
    when(() => connection.activeDeviceId).thenReturn(activeId);
    when(() => dataSource.writeAll(any())).thenAnswer((_) async {});
    when(() => dataSource.writeLastDeviceId(any())).thenAnswer((_) async {});
    repository = KnownDevicesRepository(
      dataSource: dataSource,
      connection: connection,
    );
  });

  group('load', () {
    test('maps stored devices and the last device id', () async {
      when(() => dataSource.readAll()).thenAnswer(
        (_) async => const [
          KnownDeviceDto(
            id: 'a',
            name: 'S&B VZ1',
            model: 'veazy',
            finish: 'match',
            detectedFinish: 'blue',
            lastConnectedAt: '2026-11-16T20:00:00.000',
          ),
          KnownDeviceDto(
            id: 'b',
            name: 'S&B VOLCANO H',
            model: 'volcanoHybrid',
            finish: 'lava',
          ),
        ],
      );
      when(() => dataSource.readLastDeviceId()).thenAnswer((_) async => 'a');

      final result = await repository.load();

      expect(result.isRight(), isTrue);
      final [first, second] = repository.devices.value;
      expect(first.model, DeviceModel.veazy);
      expect(first.finishPreference, const MatchDevice());
      expect(first.detectedFinish, DeviceFinish.blue);
      expect(first.lastConnectedAt, lastWeek);
      expect(second.finishPreference, const FixedFinish(DeviceFinish.lava));
      expect(second.lastConnectedAt, isNull);
      expect(repository.lastDeviceId.value, 'a');
    });

    test('skips entries it cannot read', () async {
      when(() => dataSource.readAll()).thenAnswer(
        (_) async => const [
          KnownDeviceDto(id: 'x', name: 'x', model: 'mighty', finish: 'match'),
          KnownDeviceDto(id: 'a', name: 'a', model: 'venty', finish: 'nope'),
        ],
      );
      when(() => dataSource.readLastDeviceId()).thenAnswer((_) async => null);

      await repository.load();

      expect(repository.devices.value.map((d) => d.id), ['a']);
      expect(
        repository.devices.value.single.finishPreference,
        const MatchDevice(),
      );
    });

    test('returns a storage error when reading fails', () async {
      when(() => dataSource.readAll()).thenThrow(const FormatException());

      final result = await repository.load();

      expect(result.getLeft().toNullable(), isA<StorageError>());
      expect(repository.devices.value, isEmpty);
    });
  });

  group('save', () {
    test('adds a new device and persists it', () async {
      final result = await repository.save(veazy);

      expect(result.isRight(), isTrue);
      expect(repository.devices.value, [veazy]);
      final written =
          verify(() => dataSource.writeAll(captureAny())).captured.single
              as List<KnownDeviceDto>;
      expect(written.single.id, veazy.id);
      expect(written.single.finish, 'match');
    });

    test('replaces an existing device in place', () async {
      await repository.save(veazy);
      await repository.save(volcano);

      final renamed = veazy.copyWith(name: 'Mine');
      await repository.save(renamed);

      expect(repository.devices.value, [renamed, volcano]);
    });

    test('keeps the old state when writing fails', () async {
      when(() => dataSource.writeAll(any())).thenThrow(Exception('disk'));

      final result = await repository.save(veazy);

      expect(result.getLeft().toNullable(), isA<StorageError>());
      expect(repository.devices.value, isEmpty);
    });
  });

  group('remove', () {
    test('removes the device and clears it as last device', () async {
      await repository.save(veazy);
      await repository.setLastDeviceId(veazy.id);

      final result = await repository.remove(veazy.id);

      expect(result.isRight(), isTrue);
      expect(repository.devices.value, isEmpty);
      expect(repository.lastDeviceId.value, isNull);
      verify(() => dataSource.writeLastDeviceId(null)).called(1);
    });

    test('keeps another last device', () async {
      await repository.save(veazy);
      await repository.save(volcano);
      await repository.setLastDeviceId(volcano.id);

      await repository.remove(veazy.id);

      expect(repository.lastDeviceId.value, volcano.id);
    });
  });

  test('setLastDeviceId returns a storage error on failure', () async {
    when(
      () => dataSource.writeLastDeviceId(any()),
    ).thenThrow(Exception('disk'));

    final result = await repository.setLastDeviceId('a');

    expect(result.getLeft().toNullable(), isA<StorageError>());
    expect(repository.lastDeviceId.value, isNull);
  });

  test('activeDevice follows the connection and the list', () async {
    expect(repository.activeDevice.value, isNull);

    activeId.value = veazy.id;
    expect(repository.activeDevice.value, isNull);

    await repository.save(veazy);
    expect(repository.activeDevice.value, veazy);

    final pink = veazy.copyWith(detectedFinish: DeviceFinish.pink);
    await repository.save(pink);
    expect(repository.activeDevice.value, pink);

    activeId.value = null;
    expect(repository.activeDevice.value, isNull);
  });

  group('demo device', () {
    const demo = KnownDevice(
      id: 'demo:veazy',
      name: 'kiln demo',
      model: DeviceModel.veazy,
    );

    test('save keeps it in memory, next to the saved devices', () async {
      await repository.save(veazy);
      clearInteractions(dataSource);

      final result = await repository.save(demo);

      expect(result.isRight(), isTrue);
      expect(repository.demoDevice.value, demo);
      expect(repository.devices.value, [veazy, demo]);
      expect(repository.byId('demo:veazy'), demo);
      verifyNever(() => dataSource.writeAll(any()));
    });

    test('is the active device while connected', () async {
      await repository.save(demo);
      activeId.value = 'demo:veazy';
      expect(repository.activeDevice.value, demo);
    });

    test('saving a real device does not persist the demo', () async {
      await repository.save(demo);
      await repository.save(volcano);
      final written =
          verify(() => dataSource.writeAll(captureAny())).captured.last
              as List<KnownDeviceDto>;
      expect(written.map((d) => d.id), ['volcano-id']);
    });

    test('remove forgets it without touching storage', () async {
      await repository.save(demo);
      final result = await repository.remove('demo:veazy');
      expect(result.isRight(), isTrue);
      expect(repository.demoDevice.value, isNull);
      expect(repository.devices.value, isEmpty);
      verifyNever(() => dataSource.writeAll(any()));
    });

    test('never becomes the last device', () async {
      final result = await repository.setLastDeviceId('demo:veazy');
      expect(result.isRight(), isTrue);
      expect(repository.lastDeviceId.value, isNull);
      verifyNever(() => dataSource.writeLastDeviceId(any()));
    });
  });
}
