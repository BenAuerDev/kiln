import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/domain/use_cases/adjust_volcano_target_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository repository;
  late Signal<VolcanoStatus?> status;
  late AdjustVolcanoTargetUseCase useCase;

  setUp(() {
    repository = MockVolcanoRepository();
    status = signal<VolcanoStatus?>(sampleStatus);
    when(() => repository.status).thenReturn(status);
    when(
      () => repository.setTargetTemperature(any()),
    ).thenAnswer((_) async => right(unit));
    useCase = AdjustVolcanoTargetUseCase(repository: repository);
  });

  test('raises the target by delta', () async {
    expect(await useCase(1), right(some(186)));
    verify(() => repository.setTargetTemperature(186)).called(1);
  });

  test('lowers the target by delta', () async {
    expect(await useCase(-5), right(some(180)));
    verify(() => repository.setTargetTemperature(180)).called(1);
  });

  test('clamps at 230 °C', () async {
    status.value = sampleStatus.copyWith(targetTemperature: 228);
    expect(await useCase(5), right(some(230)));
    verify(() => repository.setTargetTemperature(230)).called(1);
  });

  test('clamps at 40 °C', () async {
    status.value = sampleStatus.copyWith(targetTemperature: 42);
    expect(await useCase(-5), right(some(40)));
    verify(() => repository.setTargetTemperature(40)).called(1);
  });

  test('returns none() at the top limit without writing', () async {
    status.value = sampleStatus.copyWith(targetTemperature: 230);
    expect(await useCase(1), right(none<int>()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('returns none() at the bottom limit without writing', () async {
    status.value = sampleStatus.copyWith(targetTemperature: 40);
    expect(await useCase(-1), right(none<int>()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('returns none() for a zero delta', () async {
    expect(await useCase(0), right(none<int>()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('without a status returns NotConnected', () async {
    status.value = null;
    final result = await useCase(1);
    expect(result.getLeft().toNullable(), isA<NotConnectedError>());
  });

  test('passes repository errors on', () async {
    when(
      () => repository.setTargetTemperature(any()),
    ).thenAnswer((_) async => left(const AppError.connectionLost()));
    final result = await useCase(1);
    expect(result.getLeft().toNullable(), isA<ConnectionLostError>());
  });
}
