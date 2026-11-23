import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/models/quick_setup.dart';
import 'package:kiln/features/portable/domain/use_cases/apply_quick_setup_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late ApplyQuickSetupUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUp(() {
    repository = MockPortableRepository();
    useCase = ApplyQuickSetupUseCase(repository: repository);
    when(
      () => repository.setTargetTemperature(any()),
    ).thenAnswer((_) async => right(unit));
    when(
      () => repository.setBoostOffset(any()),
    ).thenAnswer((_) async => right(unit));
    when(
      () => repository.setSuperBoostOffset(any()),
    ).thenAnswer((_) async => right(unit));
  });

  test('writes all three values of Flavour', () async {
    givenStatus(testStatus(target: 180, boost: 15, superBoost: 15));

    final result = await useCase(QuickSetup.flavour);

    expect(result.isRight(), isTrue);
    verifyInOrder([
      () => repository.setTargetTemperature(175),
      () => repository.setBoostOffset(10),
      () => repository.setSuperBoostOffset(10),
    ]);
  });

  test('writes only the base for Full from Flavour', () async {
    givenStatus(testStatus(target: 175, boost: 10, superBoost: 10));

    await useCase(QuickSetup.full);

    verify(() => repository.setTargetTemperature(190)).called(1);
    verifyNever(() => repository.setBoostOffset(any()));
    verifyNever(() => repository.setSuperBoostOffset(any()));
  });

  test('writes only the offsets for Balanced at 180 °C', () async {
    givenStatus(testStatus(target: 180, boost: 10, superBoost: 10));

    await useCase(QuickSetup.balanced);

    verifyNever(() => repository.setTargetTemperature(any()));
    verify(() => repository.setBoostOffset(15)).called(1);
    verify(() => repository.setSuperBoostOffset(15)).called(1);
  });

  test('writes nothing when already applied', () async {
    givenStatus(testStatus(target: 180, boost: 15, superBoost: 15));

    expect((await useCase(QuickSetup.balanced)).isRight(), isTrue);
    verifyNever(() => repository.setTargetTemperature(any()));
    verifyNever(() => repository.setBoostOffset(any()));
    verifyNever(() => repository.setSuperBoostOffset(any()));
  });

  test('stops at the first error', () async {
    givenStatus(testStatus(target: 180, boost: 15, superBoost: 15));
    when(
      () => repository.setTargetTemperature(175),
    ).thenAnswer((_) async => left(const AppError.writeNotVerified('target')));

    final result = await useCase(QuickSetup.flavour);

    expect(result.getLeft().toNullable(), isA<WriteNotVerifiedError>());
    verifyNever(() => repository.setBoostOffset(any()));
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect(
      (await useCase(QuickSetup.full)).getLeft().toNullable(),
      isA<NotConnectedError>(),
    );
  });
}
