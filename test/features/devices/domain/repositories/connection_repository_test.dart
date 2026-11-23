import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/ble/ble_connection_state.dart';
import 'package:kiln/core/ble/ble_exceptions.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockDeviceConnectionDataSource dataSource;
  late StreamController<BleConnectionState> states;
  late ConnectionRepository repository;

  const delays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  var now = DateTime(2026, 11, 23);

  setUp(() {
    now = DateTime(2026, 11, 23);
    dataSource = MockDeviceConnectionDataSource();
    states = StreamController<BleConnectionState>.broadcast();
    when(() => dataSource.connect(any())).thenAnswer((_) async {});
    when(() => dataSource.disconnect(any())).thenAnswer((_) async {});
    when(
      () => dataSource.connectionState(any()),
    ).thenAnswer((_) => states.stream);
    repository = ConnectionRepository(
      dataSource: dataSource,
      retryDelays: delays,
      now: () => now,
    );
  });

  tearDown(() => states.close());

  void failConnects([Object error = const BleTimeoutException('t')]) =>
      when(() => dataSource.connect(any())).thenThrow(error);

  group('connect', () {
    test('connects and becomes the active device', () async {
      final result = await repository.connect('a');

      expect(result.isRight(), isTrue);
      expect(repository.activeDeviceId.value, 'a');
      expect(repository.status.value, ConnectionStatus.connected);
      expect(repository.disconnectedByUser.value, isFalse);
      verify(() => dataSource.connect('a')).called(1);
    });

    test('maps a failure and reports the device unavailable', () async {
      failConnects();

      final result = await repository.connect('a');

      expect(result.getLeft().toNullable(), isA<TimeoutError>());
      expect(repository.status.value, ConnectionStatus.unavailable);
      expect(repository.activeDeviceId.value, 'a');
    });

    test('does nothing when already connected to the same device', () async {
      await repository.connect('a');

      final result = await repository.connect('a');

      expect(result.isRight(), isTrue);
      verify(() => dataSource.connect('a')).called(1);
    });

    test('disconnects the previous device first', () async {
      await repository.connect('a');

      await repository.connect('b');

      verifyInOrder([
        () => dataSource.disconnect('a'),
        () => dataSource.connect('b'),
      ]);
      expect(repository.activeDeviceId.value, 'b');
      expect(repository.disconnectedByUser.value, isFalse);
    });
  });

  group('disconnect', () {
    test('clears the state and remembers it was on purpose', () async {
      await repository.connect('a');

      final result = await repository.disconnect();

      expect(result.isRight(), isTrue);
      expect(repository.activeDeviceId.value, isNull);
      expect(repository.status.value, ConnectionStatus.disconnected);
      expect(repository.disconnectedByUser.value, isTrue);
      verify(() => dataSource.disconnect('a')).called(1);
    });

    test('byUser: false keeps auto-reconnect on', () async {
      await repository.connect('a');

      final result = await repository.disconnect(byUser: false);

      expect(result.isRight(), isTrue);
      expect(repository.status.value, ConnectionStatus.disconnected);
      expect(repository.disconnectedByUser.value, isFalse);
    });

    test('returns the BLE error but still clears the state', () async {
      await repository.connect('a');
      when(
        () => dataSource.disconnect(any()),
      ).thenThrow(const BleOperationException('x'));

      final result = await repository.disconnect();

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
      expect(repository.activeDeviceId.value, isNull);
      expect(repository.status.value, ConnectionStatus.disconnected);
    });

    test('without an active device does not touch BLE', () async {
      final result = await repository.disconnect();

      expect(result.isRight(), isTrue);
      verifyNever(() => dataSource.disconnect(any()));
    });
  });

  group('auto-reconnect after an unexpected drop', () {
    test('reconnects after the first delay', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        states.add(BleConnectionState.connected);
        async.flushMicrotasks();

        states.add(BleConnectionState.disconnected);
        async.flushMicrotasks();
        expect(repository.status.value, ConnectionStatus.reconnecting);
        expect(repository.activeDeviceId.value, 'a');

        async.elapse(const Duration(milliseconds: 999));
        verify(() => dataSource.connect('a')).called(1);

        async.elapse(const Duration(milliseconds: 1));
        verify(() => dataSource.connect('a')).called(1);
        expect(repository.status.value, ConnectionStatus.connected);
      });
    });

    test('gives up after the last delay and keeps the device', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        failConnects();

        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 6));
        expect(repository.status.value, ConnectionStatus.reconnecting);

        async.elapse(const Duration(seconds: 1));
        expect(repository.status.value, ConnectionStatus.disconnected);
        expect(repository.activeDeviceId.value, 'a');
        verify(() => dataSource.connect('a')).called(1 + delays.length);
      });
    });

    test('handles a second drop after a stable connection', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 1));
        expect(repository.status.value, ConnectionStatus.connected);

        now = now.add(ConnectionRepository.stableAfter);
        states.add(BleConnectionState.disconnected);
        async.flushMicrotasks();
        expect(repository.status.value, ConnectionStatus.reconnecting);
        async.elapse(const Duration(seconds: 1));
        expect(repository.status.value, ConnectionStatus.connected);
      });
    });

    test('gives up after two short drops in a row so the device can sleep', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 1));
        expect(repository.status.value, ConnectionStatus.connected);
        clearInteractions(dataSource);

        // Real Venty: hangs up 15–30 s after each reconnect.
        now = now.add(const Duration(seconds: 30));
        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 30));

        expect(repository.status.value, ConnectionStatus.disconnected);
        expect(repository.activeDeviceId.value, 'a');
        expect(repository.disconnectedByUser.value, isFalse);
        verifyNever(() => dataSource.connect(any()));
      });
    });

    test('a stable connection resets the short-drop count', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 1));

        now = now.add(const Duration(minutes: 5));
        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 1));
        expect(repository.status.value, ConnectionStatus.connected);

        states.add(BleConnectionState.disconnected);
        async.flushMicrotasks();
        expect(repository.status.value, ConnectionStatus.reconnecting);
      });
    });

    test('reconnect after giving up tries again', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 1));
        states.add(BleConnectionState.disconnected);
        async.flushMicrotasks();
        expect(repository.status.value, ConnectionStatus.disconnected);

        unawaited(repository.reconnect('a'));
        async.flushMicrotasks();

        expect(repository.status.value, ConnectionStatus.connected);
      });
    });

    test('does not reconnect a drop while reconnecting is switched off', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        repository.setReconnectAfterDrop(false);
        now = now.add(const Duration(minutes: 10));
        clearInteractions(dataSource);

        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 30));

        expect(repository.status.value, ConnectionStatus.disconnected);
        expect(repository.activeDeviceId.value, 'a');
        verifyNever(() => dataSource.connect(any()));
      });
    });

    test('an explicit connect switches reconnecting back on', () {
      fakeAsync((async) {
        repository.setReconnectAfterDrop(false);
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        now = now.add(const Duration(minutes: 10));

        states.add(BleConnectionState.disconnected);
        async.flushMicrotasks();

        expect(repository.status.value, ConnectionStatus.reconnecting);
      });
    });

    test('a manual disconnect stops the job', () {
      fakeAsync((async) {
        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        states.add(BleConnectionState.disconnected);
        async.flushMicrotasks();

        unawaited(repository.disconnect());
        async.elapse(const Duration(seconds: 30));

        verify(() => dataSource.connect('a')).called(1);
        expect(repository.status.value, ConnectionStatus.disconnected);
        expect(repository.activeDeviceId.value, isNull);
      });
    });

    test('a drop while not connected is ignored', () {
      fakeAsync((async) {
        failConnects();
        unawaited(repository.connect('a'));
        async.flushMicrotasks();

        states.add(BleConnectionState.disconnected);
        async.elapse(const Duration(seconds: 30));

        expect(repository.status.value, ConnectionStatus.unavailable);
        verify(() => dataSource.connect('a')).called(1);
      });
    });
  });

  group('reconnect', () {
    test('tries at once and connects', () {
      fakeAsync((async) {
        Either<AppError, Object?>? result;
        repository.reconnect('a').then((r) => result = r);
        expect(repository.status.value, ConnectionStatus.reconnecting);
        async.flushMicrotasks();

        expect(result?.isRight(), isTrue);
        expect(repository.status.value, ConnectionStatus.connected);
        expect(repository.activeDeviceId.value, 'a');
      });
    });

    test('retries with backoff, then reports the last error', () {
      fakeAsync((async) {
        failConnects(const BleUnavailableException('off'));
        Either<AppError, Object?>? result;
        repository.reconnect('a').then((r) => result = r);

        async.elapse(const Duration(seconds: 5));
        expect(result, isNull);
        expect(repository.status.value, ConnectionStatus.reconnecting);

        async.elapse(const Duration(seconds: 1));
        expect(
          result?.getLeft().toNullable(),
          isA<BluetoothUnavailableError>(),
        );
        expect(repository.status.value, ConnectionStatus.disconnected);
        verify(() => dataSource.connect('a')).called(delays.length);
      });
    });

    test('stops early when permission is denied', () {
      fakeAsync((async) {
        failConnects(const BlePermissionException('no'));
        Either<AppError, Object?>? result;
        repository.reconnect('a').then((r) => result = r);
        async.flushMicrotasks();

        expect(result?.getLeft().toNullable(), isA<PermissionDeniedError>());
        expect(repository.status.value, ConnectionStatus.disconnected);
        verify(() => dataSource.connect('a')).called(1);
      });
    });

    test('joins a job that is already running', () {
      fakeAsync((async) {
        failConnects();
        unawaited(repository.reconnect('a'));
        async.flushMicrotasks();
        unawaited(repository.reconnect('a'));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 10));
        verify(() => dataSource.connect('a')).called(delays.length);
      });
    });

    test('is a no-op when already connected', () async {
      await repository.connect('a');

      final result = await repository.reconnect('a');

      expect(result.isRight(), isTrue);
      verify(() => dataSource.connect('a')).called(1);
    });

    test('an explicit connect replaces the running job', () {
      fakeAsync((async) {
        var calls = 0;
        when(() => dataSource.connect(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw const BleTimeoutException('t');
        });
        unawaited(repository.reconnect('a'));
        async.flushMicrotasks();

        unawaited(repository.connect('a'));
        async.flushMicrotasks();
        expect(repository.status.value, ConnectionStatus.connected);

        async.elapse(const Duration(seconds: 30));
        expect(calls, 2);
      });
    });
  });
}
