import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/set_base_temperature_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late SetBaseTemperatureUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUp(() {
    repository = MockPortableRepository();
    useCase = SetBaseTemperatureUseCase(repository: repository);
    when(
      () => repository.setTargetTemperature(any()),
    ).thenAnswer((_) async => right(unit));
  });

  test('writes the new temperature', () async {
    givenStatus(testStatus(target: 180));

    final result = await useCase(185);

    expect(result, right<AppError, Option<int>>(some(185)));
    verify(() => repository.setTargetTemperature(185)).called(1);
  });

  test('clamps to 210 °C', () async {
    givenStatus(testStatus(target: 180));

    expect(await useCase(250), right<AppError, Option<int>>(some(210)));
    verify(() => repository.setTargetTemperature(210)).called(1);
  });

  test('clamps to 40 °C', () async {
    givenStatus(testStatus(target: 180));

    expect(await useCase(-5), right<AppError, Option<int>>(some(40)));
    verify(() => repository.setTargetTemperature(40)).called(1);
  });

  test('returns none without writing when unchanged', () async {
    givenStatus(testStatus(target: 210));

    expect(await useCase(230), right<AppError, Option<int>>(none()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect(
      (await useCase(180)).getLeft().toNullable(),
      isA<NotConnectedError>(),
    );
  });

  test('passes write errors through', () async {
    givenStatus(testStatus(target: 180));
    when(
      () => repository.setTargetTemperature(190),
    ).thenAnswer((_) async => left(const AppError.writeNotVerified('target')));

    final result = await useCase(190);

    expect(result.getLeft().toNullable(), isA<WriteNotVerifiedError>());
  });
}
