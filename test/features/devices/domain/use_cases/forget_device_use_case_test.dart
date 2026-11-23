import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/use_cases/forget_device_use_case.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockConnectionRepository connection;
  late MockKnownDevicesRepository knownDevices;
  late ForgetDeviceUseCase useCase;

  setUp(() {
    connection = MockConnectionRepository();
    knownDevices = MockKnownDevicesRepository();
    when(() => knownDevices.byId(veazy.id)).thenReturn(veazy);
    when(() => knownDevices.byId('unknown')).thenReturn(null);
    when(() => knownDevices.remove(any())).thenAnswer((_) async => right(unit));
    when(
      () => connection.disconnect(byUser: any(named: 'byUser')),
    ).thenAnswer((_) async => right(unit));
    when(() => connection.activeDeviceId).thenReturn(signal<String?>(null));
    useCase = ForgetDeviceUseCase(
      connection: connection,
      knownDevices: knownDevices,
    );
  });

  test('removes an inactive device without disconnecting', () async {
    final result = await useCase(veazy.id);

    expect(result.isRight(), isTrue);
    verify(() => knownDevices.remove(veazy.id)).called(1);
    verifyNever(() => connection.disconnect(byUser: any(named: 'byUser')));
  });

  test('disconnects the active device first', () async {
    when(() => connection.activeDeviceId).thenReturn(signal<String?>(veazy.id));

    await useCase(veazy.id);

    verifyInOrder([
      () => connection.disconnect(byUser: true),
      () => knownDevices.remove(veazy.id),
    ]);
  });

  test('still forgets when the BLE disconnect fails', () async {
    when(() => connection.activeDeviceId).thenReturn(signal<String?>(veazy.id));
    when(
      () => connection.disconnect(byUser: true),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    final result = await useCase(veazy.id);

    expect(result.isRight(), isTrue);
    verify(() => knownDevices.remove(veazy.id)).called(1);
  });

  test('forgetting the active demo keeps auto-reconnect on', () async {
    const demo = KnownDevice(
      id: 'demo:venty',
      name: 'kiln demo',
      model: DeviceModel.venty,
    );
    when(() => knownDevices.byId(demo.id)).thenReturn(demo);
    when(() => connection.activeDeviceId).thenReturn(signal<String?>(demo.id));

    await useCase(demo.id);

    verify(() => connection.disconnect(byUser: false)).called(1);
    verify(() => knownDevices.remove(demo.id)).called(1);
  });

  test('unknown device', () async {
    final result = await useCase('unknown');

    expect(result.getLeft().toNullable(), isA<DeviceNotFoundError>());
    verifyNever(() => knownDevices.remove(any()));
  });

  test('passes a storage error on', () async {
    when(
      () => knownDevices.remove(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase(veazy.id);

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
