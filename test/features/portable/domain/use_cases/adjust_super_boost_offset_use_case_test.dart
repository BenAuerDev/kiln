import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/adjust_super_boost_offset_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late AdjustSuperBoostOffsetUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUp(() {
    repository = MockPortableRepository();
    useCase = AdjustSuperBoostOffsetUseCase(repository: repository);
    when(
      () => repository.setSuperBoostOffset(any()),
    ).thenAnswer((_) async => right(unit));
  });

  test('raises by one degree', () async {
    givenStatus(testStatus(superBoost: 15));

    expect(await useCase(1), right<AppError, Option<int>>(some(16)));
    verify(() => repository.setSuperBoostOffset(16)).called(1);
  });

  test('lowers by one degree', () async {
    givenStatus(testStatus(superBoost: 15));

    expect(await useCase(-1), right<AppError, Option<int>>(some(14)));
  });

  test('clamps at 30', () async {
    givenStatus(testStatus(superBoost: 28));

    expect(await useCase(5), right<AppError, Option<int>>(some(30)));
  });

  test('clamps at 1', () async {
    givenStatus(testStatus(superBoost: 3));

    expect(await useCase(-5), right<AppError, Option<int>>(some(1)));
  });

  test('returns none at the upper limit', () async {
    givenStatus(testStatus(superBoost: 30));

    expect(await useCase(1), right<AppError, Option<int>>(none()));
    verifyNever(() => repository.setSuperBoostOffset(any()));
  });

  test('returns none at the lower limit', () async {
    givenStatus(testStatus(superBoost: 1));

    expect(await useCase(-1), right<AppError, Option<int>>(none()));
    verifyNever(() => repository.setSuperBoostOffset(any()));
  });

  test('a device value above 30 is never raised further', () async {
    // The device itself allows up to 99.
    givenStatus(testStatus(superBoost: 50));

    expect(await useCase(1), right<AppError, Option<int>>(none()));
    expect(await useCase(-1), right<AppError, Option<int>>(some(30)));
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect((await useCase(1)).getLeft().toNullable(), isA<NotConnectedError>());
  });

  test('passes write errors through', () async {
    givenStatus(testStatus(superBoost: 15));
    when(
      () => repository.setSuperBoostOffset(16),
    ).thenAnswer((_) async => left(const AppError.connectionLost()));

    expect(
      (await useCase(1)).getLeft().toNullable(),
      isA<ConnectionLostError>(),
    );
  });
}
