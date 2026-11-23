import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/use_cases/load_known_devices_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockKnownDevicesRepository knownDevices;

  setUp(() => knownDevices = MockKnownDevicesRepository());

  test('loads the known devices', () async {
    when(() => knownDevices.load()).thenAnswer((_) async => right(unit));

    final result = await LoadKnownDevicesUseCase(knownDevices: knownDevices)();

    expect(result.isRight(), isTrue);
    verify(() => knownDevices.load()).called(1);
  });

  test('passes a storage error on', () async {
    when(
      () => knownDevices.load(),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await LoadKnownDevicesUseCase(knownDevices: knownDevices)();

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
