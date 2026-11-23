import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/finish_preference.dart';
import 'package:kiln/features/devices/domain/use_cases/set_device_finish_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockKnownDevicesRepository knownDevices;
  late SetDeviceFinishUseCase useCase;

  setUpAll(() => registerFallbackValue(veazy));

  setUp(() {
    knownDevices = MockKnownDevicesRepository();
    when(() => knownDevices.byId(veazy.id)).thenReturn(veazy);
    when(() => knownDevices.byId('unknown')).thenReturn(null);
    when(() => knownDevices.save(any())).thenAnswer((_) async => right(unit));
    useCase = SetDeviceFinishUseCase(knownDevices: knownDevices);
  });

  test('stores a fixed finish', () async {
    final result = await useCase(
      veazy.id,
      const FixedFinish(DeviceFinish.pink),
    );

    expect(result.isRight(), isTrue);
    verify(
      () => knownDevices.save(
        veazy.copyWith(finishPreference: const FixedFinish(DeviceFinish.pink)),
      ),
    ).called(1);
  });

  test('switches back to match my device', () async {
    final fixed = veazy.copyWith(
      finishPreference: const FixedFinish(DeviceFinish.mono),
    );
    when(() => knownDevices.byId(veazy.id)).thenReturn(fixed);

    await useCase(veazy.id, const MatchDevice());

    final saved = verify(() => knownDevices.save(captureAny())).captured.single;
    expect(saved, veazy);
  });

  test('does not write an unchanged preference', () async {
    final result = await useCase(veazy.id, const MatchDevice());

    expect(result.isRight(), isTrue);
    verifyNever(() => knownDevices.save(any()));
  });

  test('unknown device', () async {
    final result = await useCase('unknown', const MatchDevice());

    expect(result.getLeft().toNullable(), isA<DeviceNotFoundError>());
  });

  test('passes a storage error on', () async {
    when(
      () => knownDevices.save(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase(
      veazy.id,
      const FixedFinish(DeviceFinish.blue),
    );

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
