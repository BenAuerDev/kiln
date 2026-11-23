import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/update_portable_settings_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late UpdatePortableSettingsUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUpAll(() => registerFallbackValue(testSettings));

  setUp(() {
    repository = MockPortableRepository();
    useCase = UpdatePortableSettingsUseCase(repository: repository);
  });

  test('writes changed settings', () async {
    final changed = testSettings.copyWith(fahrenheit: true);
    givenStatus(testStatus());
    when(
      () => repository.setSettings(changed),
    ).thenAnswer((_) async => right(unit));

    expect((await useCase(changed)).isRight(), isTrue);
    verify(() => repository.setSettings(changed)).called(1);
  });

  test('does nothing when unchanged', () async {
    givenStatus(testStatus());

    expect((await useCase(testSettings)).isRight(), isTrue);
    verifyNever(() => repository.setSettings(any()));
  });

  test('passes write errors through', () async {
    final changed = testSettings.copyWith(ecoCharge: true);
    givenStatus(testStatus());
    when(
      () => repository.setSettings(changed),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    expect(
      (await useCase(changed)).getLeft().toNullable(),
      isA<TimeoutError>(),
    );
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect(
      (await useCase(testSettings)).getLeft().toNullable(),
      isA<NotConnectedError>(),
    );
  });
}
