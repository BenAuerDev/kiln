import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/use_cases/reconnect_last_device_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockConnectionRepository connection;
  late MockKnownDevicesRepository knownDevices;
  late Signal<String?> lastId;
  late Signal<ConnectionStatus> status;
  late Signal<bool> byUser;
  late ReconnectLastDeviceUseCase useCase;

  setUpAll(() => registerFallbackValue(veazy));

  setUp(() {
    connection = MockConnectionRepository();
    knownDevices = MockKnownDevicesRepository();
    lastId = signal<String?>(veazy.id);
    status = signal(ConnectionStatus.disconnected);
    byUser = signal(false);
    when(() => knownDevices.lastDeviceId).thenReturn(lastId);
    when(() => knownDevices.byId(veazy.id)).thenReturn(veazy);
    when(() => knownDevices.save(any())).thenAnswer((_) async => right(unit));
    when(() => connection.status).thenReturn(status);
    when(() => connection.disconnectedByUser).thenReturn(byUser);
    when(
      () => connection.reconnect(any()),
    ).thenAnswer((_) async => right(unit));
    useCase = ReconnectLastDeviceUseCase(
      connection: connection,
      knownDevices: knownDevices,
      clock: () => fixedNow,
    );
  });

  test('reconnects to the last device and updates its last use', () async {
    final result = await useCase();

    final updated = veazy.copyWith(lastConnectedAt: fixedNow);
    expect(result.toNullable(), some(updated));
    verify(() => connection.reconnect(veazy.id)).called(1);
    verify(() => knownDevices.save(updated)).called(1);
  });

  test('works from unavailable after a failed connect', () async {
    status.value = ConnectionStatus.unavailable;

    await useCase();

    verify(() => connection.reconnect(veazy.id)).called(1);
  });

  test('nothing to do without a last device', () async {
    lastId.value = null;

    final result = await useCase();

    expect(result.toNullable(), none());
    verifyNever(() => connection.reconnect(any()));
  });

  test('nothing to do when the last device was forgotten', () async {
    when(() => knownDevices.byId(veazy.id)).thenReturn(null);

    final result = await useCase();

    expect(result.toNullable(), none());
    verifyNever(() => connection.reconnect(any()));
  });

  for (final busy in [
    ConnectionStatus.connecting,
    ConnectionStatus.connected,
    ConnectionStatus.reconnecting,
  ]) {
    test('leaves a ${busy.name} connection alone', () async {
      status.value = busy;

      final result = await useCase();

      expect(result.toNullable(), none());
      verifyNever(() => connection.reconnect(any()));
    });
  }

  test('respects a manual disconnect', () async {
    byUser.value = true;

    final result = await useCase();

    expect(result.toNullable(), none());
    verifyNever(() => connection.reconnect(any()));
  });

  test('passes the reconnect error on', () async {
    when(
      () => connection.reconnect(any()),
    ).thenAnswer((_) async => left(const AppError.bluetoothUnavailable()));

    final result = await useCase();

    expect(result.getLeft().toNullable(), isA<BluetoothUnavailableError>());
    verifyNever(() => knownDevices.save(any()));
  });

  test('does not bring back a device forgotten meanwhile', () async {
    when(() => connection.reconnect(any())).thenAnswer((_) async {
      when(() => knownDevices.byId(veazy.id)).thenReturn(null);
      return right(unit);
    });

    final result = await useCase();

    expect(result.toNullable(), none());
    verifyNever(() => knownDevices.save(any()));
  });

  test('passes a storage error on', () async {
    when(
      () => knownDevices.save(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase();

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
