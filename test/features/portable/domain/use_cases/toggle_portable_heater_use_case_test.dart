import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/toggle_portable_heater_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late TogglePortableHeaterUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUpAll(() => registerFallbackValue(HeaterMode.off));

  setUp(() {
    repository = MockPortableRepository();
    useCase = TogglePortableHeaterUseCase(repository: repository);
    when(
      () => repository.setHeaterMode(any()),
    ).thenAnswer((_) async => right(unit));
  });

  test('switches an idle heater on in normal mode', () async {
    givenStatus(testStatus(heaterMode: HeaterMode.off));

    expect(await useCase(), right<AppError, HeaterMode>(HeaterMode.normal));
    verify(() => repository.setHeaterMode(HeaterMode.normal)).called(1);
  });

  test('switches a running heater off', () async {
    givenStatus(testStatus(heaterMode: HeaterMode.normal));

    expect(await useCase(), right<AppError, HeaterMode>(HeaterMode.off));
    verify(() => repository.setHeaterMode(HeaterMode.off)).called(1);
  });

  for (final mode in [HeaterMode.boost, HeaterMode.superboost]) {
    test('switches the heater off from $mode', () async {
      givenStatus(testStatus(heaterMode: mode));

      expect(await useCase(), right<AppError, HeaterMode>(HeaterMode.off));
      verify(() => repository.setHeaterMode(HeaterMode.off)).called(1);
    });
  }

  test('passes a write error through', () async {
    givenStatus(testStatus(heaterMode: HeaterMode.off));
    when(
      () => repository.setHeaterMode(any()),
    ).thenAnswer((_) async => left(const AppError.connectionLost()));

    expect(
      (await useCase()).getLeft().toNullable(),
      isA<ConnectionLostError>(),
    );
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect((await useCase()).getLeft().toNullable(), isA<NotConnectedError>());
    verifyNever(() => repository.setHeaterMode(any()));
  });
}
