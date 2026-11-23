import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/domain/use_cases/toggle_volcano_pump_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockVolcanoRepository repository;
  late Signal<VolcanoStatus?> status;
  late ToggleVolcanoPumpUseCase useCase;

  setUp(() {
    repository = MockVolcanoRepository();
    status = signal<VolcanoStatus?>(sampleStatus);
    when(() => repository.status).thenReturn(status);
    when(() => repository.setPump(any())).thenAnswer((_) async => right(unit));
    useCase = ToggleVolcanoPumpUseCase(repository: repository);
  });

  test('switches on when off', () async {
    status.value = sampleStatus.copyWith(pumpOn: false);
    expect(await useCase(), right(true));
    verify(() => repository.setPump(true)).called(1);
  });

  test('switches off when on', () async {
    status.value = sampleStatus.copyWith(pumpOn: true);
    expect(await useCase(), right(false));
    verify(() => repository.setPump(false)).called(1);
  });

  test('without a status returns NotConnected and writes nothing', () async {
    status.value = null;
    final result = await useCase();
    expect(result.getLeft().toNullable(), isA<NotConnectedError>());
    verifyNever(() => repository.setPump(any()));
  });

  test('passes repository errors on', () async {
    when(
      () => repository.setPump(any()),
    ).thenAnswer((_) async => left(const AppError.writeNotVerified('x')));
    final result = await useCase();
    expect(result.getLeft().toNullable(), isA<WriteNotVerifiedError>());
  });
}
