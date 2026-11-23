import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/domain/use_cases/toggle_volcano_heater_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository repository;
  late Signal<VolcanoStatus?> status;
  late ToggleVolcanoHeaterUseCase useCase;

  setUp(() {
    repository = MockVolcanoRepository();
    status = signal<VolcanoStatus?>(sampleStatus);
    when(() => repository.status).thenReturn(status);
    when(
      () => repository.setHeater(any()),
    ).thenAnswer((_) async => right(unit));
    useCase = ToggleVolcanoHeaterUseCase(repository: repository);
  });

  test('switches on when off', () async {
    status.value = sampleStatus.copyWith(heaterOn: false);
    expect(await useCase(), right(true));
    verify(() => repository.setHeater(true)).called(1);
  });

  test('switches off when on', () async {
    status.value = sampleStatus.copyWith(heaterOn: true);
    expect(await useCase(), right(false));
    verify(() => repository.setHeater(false)).called(1);
  });

  test('without a status returns NotConnected and writes nothing', () async {
    status.value = null;
    final result = await useCase();
    expect(result.getLeft().toNullable(), isA<NotConnectedError>());
    verifyNever(() => repository.setHeater(any()));
  });

  test('passes repository errors on', () async {
    when(
      () => repository.setHeater(any()),
    ).thenAnswer((_) async => left(const AppError.writeNotVerified('x')));
    final result = await useCase();
    expect(result.getLeft().toNullable(), isA<WriteNotVerifiedError>());
  });
}
