import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/toggle_portable_boost_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late TogglePortableBoostUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUpAll(() => registerFallbackValue(HeaterMode.off));

  setUp(() {
    repository = MockPortableRepository();
    useCase = TogglePortableBoostUseCase(repository: repository);
  });

  for (final mode in [HeaterMode.off, HeaterMode.normal]) {
    test('asks for boost from $mode', () async {
      givenStatus(testStatus(heaterMode: mode));
      when(
        () => repository.setHeaterMode(HeaterMode.boost),
      ).thenAnswer((_) async => right(unit));

      expect(await useCase(), right<AppError, HeaterMode>(HeaterMode.boost));
      verify(() => repository.setHeaterMode(HeaterMode.boost)).called(1);
    });
  }

  test('passes the blocked boost write through', () async {
    givenStatus(testStatus(heaterMode: HeaterMode.normal));
    when(() => repository.setHeaterMode(HeaterMode.boost)).thenAnswer(
      (_) async => left(const AppError.writeNotVerified('heaterBoost')),
    );

    expect(
      (await useCase()).getLeft().toNullable(),
      isA<WriteNotVerifiedError>(),
    );
  });

  group('cycle', () {
    test('goes from boost to superboost', () async {
      givenStatus(testStatus(heaterMode: HeaterMode.boost));
      when(
        () => repository.setHeaterMode(any()),
      ).thenAnswer((_) async => right(unit));

      expect(
        await useCase(),
        right<AppError, HeaterMode>(HeaterMode.superboost),
      );
      verify(() => repository.setHeaterMode(HeaterMode.superboost)).called(1);
      verifyNever(() => repository.setHeaterMode(HeaterMode.off));
    });

    test('ends superboost with heater off, then on at base', () async {
      givenStatus(testStatus(heaterMode: HeaterMode.superboost));
      when(
        () => repository.setHeaterMode(any()),
      ).thenAnswer((_) async => right(unit));

      expect(await useCase(), right<AppError, HeaterMode>(HeaterMode.normal));
      verifyInOrder([
        () => repository.setHeaterMode(HeaterMode.off),
        () => repository.setHeaterMode(HeaterMode.normal),
      ]);
    });

    test('still starts with boost from normal', () async {
      givenStatus(testStatus(heaterMode: HeaterMode.normal));
      when(
        () => repository.setHeaterMode(any()),
      ).thenAnswer((_) async => right(unit));
      expect(await useCase(), right<AppError, HeaterMode>(HeaterMode.boost));
    });
  });

  test('stops when switching off fails', () async {
    givenStatus(testStatus(heaterMode: HeaterMode.superboost));
    when(
      () => repository.setHeaterMode(HeaterMode.off),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    expect((await useCase()).getLeft().toNullable(), isA<TimeoutError>());
    verifyNever(() => repository.setHeaterMode(HeaterMode.normal));
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect((await useCase()).getLeft().toNullable(), isA<NotConnectedError>());
    verifyNever(() => repository.setHeaterMode(any()));
  });
}
