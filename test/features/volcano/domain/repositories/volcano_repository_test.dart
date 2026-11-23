import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/ble/ble_connection_state.dart';
import 'package:kiln/core/ble/ble_exceptions.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/volcano/data/models/volcano_registers_dto.dart';
import 'package:kiln/features/volcano/data/models/volcano_write_safety.dart';
import 'package:kiln/features/volcano/domain/repositories/volcano_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  const id = 'AA:BB';
  late MockVolcanoBleDataSource dataSource;
  late VolcanoRepository repository;
  late StreamController<double?> current;
  late StreamController<double?> target;
  late StreamController<VolcanoRegister1Dto> register1;
  late StreamController<VolcanoRegister2Dto> register2;
  late StreamController<BleConnectionState> connection;

  setUp(() {
    dataSource = MockVolcanoBleDataSource();
    repository = VolcanoRepository(dataSource: dataSource);
    current = StreamController();
    target = StreamController();
    register1 = StreamController();
    register2 = StreamController();
    connection = StreamController.broadcast();

    when(
      () => dataSource.readCurrentTemperature(id),
    ).thenAnswer((_) async => 96.5);
    when(
      () => dataSource.readTargetTemperature(id),
    ).thenAnswer((_) async => 185);
    when(() => dataSource.readRegister1(id)).thenAnswer(
      (_) async => const VolcanoRegister1Dto(
        heaterOn: true,
        autoShutdown: true,
        pumpOn: false,
      ),
    );
    when(() => dataSource.readRegister2(id)).thenAnswer(
      (_) async =>
          const VolcanoRegister2Dto(fahrenheit: false, displayOnCooling: true),
    );
    when(() => dataSource.readRegister3(id)).thenAnswer(
      (_) async => const VolcanoRegister3Dto(vibrationWhenReady: true),
    );
    when(
      () => dataSource.watchCurrentTemperature(id),
    ).thenAnswer((_) => current.stream);
    when(
      () => dataSource.watchTargetTemperature(id),
    ).thenAnswer((_) => target.stream);
    when(
      () => dataSource.watchRegister1(id),
    ).thenAnswer((_) => register1.stream);
    when(
      () => dataSource.watchRegister2(id),
    ).thenAnswer((_) => register2.stream);
    when(
      () => dataSource.connectionState(id),
    ).thenAnswer((_) => connection.stream);
  });

  group('connection loss', () {
    test('ends the session when the link drops', () async {
      await repository.startSession(id);

      connection.add(BleConnectionState.disconnected);
      await pumpEventQueue();

      expect(repository.sessionActive.value, isFalse);
      expect(repository.status.value, isNull);
    });

    test('a new start after a drop reads everything again', () async {
      await repository.startSession(id);
      connection.add(BleConnectionState.disconnected);
      await pumpEventQueue();
      clearInteractions(dataSource);
      current = StreamController();
      target = StreamController();
      register1 = StreamController();
      register2 = StreamController();

      await repository.startSession(id);

      verify(() => dataSource.readTargetTemperature(id)).called(1);
      expect(repository.sessionActive.value, isTrue);
    });
  });

  group('startSession', () {
    test('reads the initial status and marks the session active', () async {
      final result = await repository.startSession(id);

      expect(result, right(unit));
      expect(repository.status.value, sampleStatus);
      expect(repository.sessionActive.value, isTrue);
    });

    test('a second start for the same device does not read again', () async {
      await repository.startSession(id);
      await repository.startSession(id);

      verify(() => dataSource.readTargetTemperature(id)).called(1);
    });

    test('concurrent starts share one session', () async {
      await Future.wait([
        repository.startSession(id),
        repository.startSession(id),
      ]);

      verify(() => dataSource.readTargetTemperature(id)).called(1);
      verify(() => dataSource.watchCurrentTemperature(id)).called(1);
    });

    test('a failed read returns Left and leaves no session', () async {
      when(
        () => dataSource.readRegister1(id),
      ).thenThrow(const BleTimeoutException('read'));

      final result = await repository.startSession(id);

      expect(result.getLeft().toNullable(), isA<TimeoutError>());
      expect(repository.status.value, isNull);
      expect(repository.sessionActive.value, isFalse);
    });

    test('an unreadable target is a protocol error', () async {
      when(
        () => dataSource.readTargetTemperature(id),
      ).thenAnswer((_) async => null);

      final result = await repository.startSession(id);

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
    });

    test('an invalid current reading starts with no temperature', () async {
      when(
        () => dataSource.readCurrentTemperature(id),
      ).thenAnswer((_) async => null);

      await repository.startSession(id);

      expect(repository.status.value?.currentTemperature, isNull);
    });
  });

  group('notifications', () {
    setUp(() => repository.startSession(id));

    test('update temperatures and ignore invalid readings', () async {
      current.add(150.2);
      target.add(199.6);
      await pumpEventQueue();
      expect(repository.status.value?.currentTemperature, 150.2);
      expect(repository.status.value?.targetTemperature, 200);

      current.add(null);
      await pumpEventQueue();
      expect(repository.status.value?.currentTemperature, 150.2);
    });

    test('update heater, pump and settings from registers', () async {
      register1.add(
        const VolcanoRegister1Dto(
          heaterOn: false,
          autoShutdown: false,
          pumpOn: true,
        ),
      );
      register2.add(
        const VolcanoRegister2Dto(fahrenheit: true, displayOnCooling: false),
      );
      await pumpEventQueue();

      final status = repository.status.value!;
      expect(status.heaterOn, isFalse);
      expect(status.pumpOn, isTrue);
      expect(status.autoShutdown, isFalse);
      expect(status.fahrenheit, isTrue);
      expect(status.displayOnCooling, isFalse);
    });

    test('stream errors keep the session alive', () async {
      current.addError(const BleOperationException('notify'));
      await pumpEventQueue();
      expect(repository.sessionActive.value, isTrue);
    });
  });

  group('stopSession', () {
    test('clears status and cancels notifications', () async {
      await repository.startSession(id);

      final result = await repository.stopSession();

      expect(result, right(unit));
      expect(repository.status.value, isNull);
      expect(repository.sessionActive.value, isFalse);
      expect(current.hasListener, isFalse);
      expect(register1.hasListener, isFalse);
    });

    test('a start superseded by stop does not become active', () async {
      final start = repository.startSession(id);
      await repository.stopSession();

      final result = await start;

      expect(result.isLeft(), isTrue);
      expect(repository.sessionActive.value, isFalse);
      expect(repository.status.value, isNull);
    });
  });

  group('writes', () {
    test('without a session return NotConnected and send nothing', () async {
      final result = await repository.setHeater(true);

      expect(result.getLeft().toNullable(), isA<NotConnectedError>());
      verifyNever(() => dataSource.writeHeater(any(), on: any(named: 'on')));
    });

    group('with a session', () {
      setUp(() => repository.startSession(id));

      test('setTargetTemperature writes and updates optimistically', () async {
        final write = Completer<void>();
        when(
          () => dataSource.writeTargetTemperature(id, 200),
        ).thenAnswer((_) => write.future);

        final result = repository.setTargetTemperature(200);
        expect(repository.status.value?.targetTemperature, 200);
        write.complete();

        expect(await result, right(unit));
        expect(repository.status.value?.targetTemperature, 200);
      });

      test('a failed write reverts and returns Left', () async {
        when(
          () => dataSource.writeTargetTemperature(id, 200),
        ).thenThrow(const BleConnectionException('gone'));

        final result = await repository.setTargetTemperature(200);

        expect(result.getLeft().toNullable(), isA<ConnectionFailedError>());
        expect(repository.status.value?.targetTemperature, 185);
      });

      test('setHeater and setPump write the requested state', () async {
        when(
          () => dataSource.writeHeater(id, on: false),
        ).thenAnswer((_) async {});
        when(() => dataSource.writePump(id, on: true)).thenAnswer((_) async {});

        expect(await repository.setHeater(false), right(unit));
        expect(await repository.setPump(true), right(unit));

        expect(repository.status.value?.heaterOn, isFalse);
        expect(repository.status.value?.pumpOn, isTrue);
      });

      test('a blocked write maps to WriteNotVerified', () async {
        when(
          () => dataSource.writePump(id, on: true),
        ).thenThrow(const VolcanoWriteNotAllowedException('x'));

        final result = await repository.setPump(true);

        expect(result.getLeft().toNullable(), isA<WriteNotVerifiedError>());
        expect(repository.status.value?.pumpOn, isFalse);
      });
    });
  });
}
