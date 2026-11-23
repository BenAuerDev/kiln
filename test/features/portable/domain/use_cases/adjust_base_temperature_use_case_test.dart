import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/adjust_base_temperature_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late AdjustBaseTemperatureUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUp(() {
    repository = MockPortableRepository();
    useCase = AdjustBaseTemperatureUseCase(repository: repository);
    when(
      () => repository.setTargetTemperature(any()),
    ).thenAnswer((_) async => right(unit));
  });

  test('raises by one degree', () async {
    givenStatus(testStatus(target: 180));

    expect(await useCase(1), right<AppError, Option<int>>(some(181)));
    verify(() => repository.setTargetTemperature(181)).called(1);
  });

  test('lowers by several degrees', () async {
    givenStatus(testStatus(target: 180));

    expect(await useCase(-5), right<AppError, Option<int>>(some(175)));
  });

  test('clamps at 210 °C', () async {
    givenStatus(testStatus(target: 208));

    expect(await useCase(5), right<AppError, Option<int>>(some(210)));
  });

  test('clamps at 40 °C', () async {
    givenStatus(testStatus(target: 42));

    expect(await useCase(-5), right<AppError, Option<int>>(some(40)));
  });

  test('returns none at the upper limit', () async {
    givenStatus(testStatus(target: 210));

    expect(await useCase(1), right<AppError, Option<int>>(none()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('returns none at the lower limit', () async {
    givenStatus(testStatus(target: 40));

    expect(await useCase(-1), right<AppError, Option<int>>(none()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('returns none for a zero delta', () async {
    givenStatus(testStatus(target: 180));

    expect(await useCase(0), right<AppError, Option<int>>(none()));
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect((await useCase(1)).getLeft().toNullable(), isA<NotConnectedError>());
  });

  test('passes write errors through', () async {
    givenStatus(testStatus(target: 180));
    when(
      () => repository.setTargetTemperature(181),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    expect((await useCase(1)).getLeft().toNullable(), isA<TimeoutError>());
  });
}
