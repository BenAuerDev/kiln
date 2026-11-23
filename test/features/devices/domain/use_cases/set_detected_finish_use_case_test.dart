import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/use_cases/set_detected_finish_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockKnownDevicesRepository knownDevices;
  late SetDetectedFinishUseCase useCase;

  setUpAll(() => registerFallbackValue(veazy));

  setUp(() {
    knownDevices = MockKnownDevicesRepository();
    when(() => knownDevices.byId(veazy.id)).thenReturn(veazy);
    when(() => knownDevices.byId('unknown')).thenReturn(null);
    when(() => knownDevices.save(any())).thenAnswer((_) async => right(unit));
    useCase = SetDetectedFinishUseCase(knownDevices: knownDevices);
  });

  test('stores the detected finish', () async {
    final result = await useCase(veazy.id, DeviceFinish.blue);

    expect(result.isRight(), isTrue);
    verify(
      () =>
          knownDevices.save(veazy.copyWith(detectedFinish: DeviceFinish.blue)),
    ).called(1);
  });

  test('skips the write when nothing changed', () async {
    when(
      () => knownDevices.byId(veazy.id),
    ).thenReturn(veazy.copyWith(detectedFinish: DeviceFinish.blue));

    await useCase(veazy.id, DeviceFinish.blue);

    verifyNever(() => knownDevices.save(any()));
  });

  test('unknown device', () async {
    final result = await useCase('unknown', DeviceFinish.pink);

    expect(result.getLeft().toNullable(), isA<DeviceNotFoundError>());
  });

  test('passes a storage error on', () async {
    when(
      () => knownDevices.save(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase(veazy.id, DeviceFinish.pink);

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
