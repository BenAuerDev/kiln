import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/domain/use_cases/set_volcano_target_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository repository;
  late Signal<VolcanoStatus?> status;
  late SetVolcanoTargetUseCase useCase;

  setUp(() {
    repository = MockVolcanoRepository();
    status = signal<VolcanoStatus?>(sampleStatus);
    when(() => repository.status).thenReturn(status);
    when(
      () => repository.setTargetTemperature(any()),
    ).thenAnswer((_) async => right(unit));
    useCase = SetVolcanoTargetUseCase(repository: repository);
  });

  test('writes a new target and returns it', () async {
    expect(await useCase(200), right(some(200)));
    verify(() => repository.setTargetTemperature(200)).called(1);
  });

  test('clamps to 230 °C at the top', () async {
    expect(await useCase(260), right(some(230)));
    verify(() => repository.setTargetTemperature(230)).called(1);
  });

  test('clamps to 40 °C at the bottom', () async {
    expect(await useCase(10), right(some(40)));
    verify(() => repository.setTargetTemperature(40)).called(1);
  });

  test('returns none() and writes nothing when unchanged', () async {
    expect(await useCase(185), right(none<int>()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('returns none() when clamping lands on the current target', () async {
    status.value = sampleStatus.copyWith(targetTemperature: 230);
    expect(await useCase(999), right(none<int>()));
    verifyNever(() => repository.setTargetTemperature(any()));
  });

  test('without a status returns NotConnected', () async {
    status.value = null;
    final result = await useCase(200);
    expect(result.getLeft().toNullable(), isA<NotConnectedError>());
  });

  test('passes repository errors on', () async {
    when(
      () => repository.setTargetTemperature(any()),
    ).thenAnswer((_) async => left(const AppError.timeout()));
    final result = await useCase(200);
    expect(result.getLeft().toNullable(), isA<TimeoutError>());
  });
}
