import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/volcano/domain/use_cases/start_volcano_session_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository repository;
  late MockKnownDevicesRepository knownDevices;
  late StartVolcanoSessionUseCase useCase;

  void knownAs(DeviceModel model) => when(
    () => knownDevices.byId('AA'),
  ).thenReturn(KnownDevice(id: 'AA', name: 'Device', model: model));

  setUp(() {
    repository = MockVolcanoRepository();
    knownDevices = MockKnownDevicesRepository();
    useCase = StartVolcanoSessionUseCase(
      repository: repository,
      knownDevices: knownDevices,
    );
  });

  test('starts a session for a Volcano Hybrid', () async {
    knownAs(DeviceModel.volcanoHybrid);
    when(
      () => repository.startSession('AA'),
    ).thenAnswer((_) async => right(unit));

    expect(await useCase('AA'), right<AppError, Unit>(unit));
    verify(() => repository.startSession('AA')).called(1);
  });

  test('passes errors on', () async {
    knownAs(DeviceModel.volcanoHybrid);
    when(
      () => repository.startSession('AA'),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    final result = await useCase('AA');

    expect(result.getLeft().toNullable(), isA<TimeoutError>());
  });

  test('does not start a session for a portable', () async {
    knownAs(DeviceModel.veazy);

    final result = await useCase('AA');

    expect(result.getLeft().toNullable(), isA<NotConnectedError>());
    verifyNever(() => repository.startSession(any()));
  });

  test('does not start a session for an unknown device', () async {
    when(() => knownDevices.byId('AA')).thenReturn(null);

    final result = await useCase('AA');

    expect(result.getLeft().toNullable(), isA<NotConnectedError>());
    verifyNever(() => repository.startSession(any()));
  });
}
