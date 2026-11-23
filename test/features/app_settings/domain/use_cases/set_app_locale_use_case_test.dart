import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:kiln/features/app_settings/domain/use_cases/set_app_locale_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

void main() {
  late MockAppSettingsRepository repository;
  late SetAppLocaleUseCase useCase;

  setUp(() {
    repository = MockAppSettingsRepository();
    useCase = SetAppLocaleUseCase(repository: repository);
  });

  test('stores a supported language', () async {
    when(
      () => repository.setLocaleCode('de'),
    ).thenAnswer((_) async => right(unit));

    final result = await useCase('de');

    expect(result.isRight(), isTrue);
    verify(() => repository.setLocaleCode('de')).called(1);
  });

  test('null follows the system language', () async {
    when(
      () => repository.setLocaleCode(null),
    ).thenAnswer((_) async => right(unit));

    final result = await useCase(null);

    expect(result.isRight(), isTrue);
    verify(() => repository.setLocaleCode(null)).called(1);
  });

  test('rejects an unsupported language without storing it', () async {
    final result = await useCase('fr');

    expect(result.getLeft().toNullable(), isA<ProtocolError>());
    verifyNever(() => repository.setLocaleCode(any()));
  });

  test('passes storage errors through', () async {
    when(
      () => repository.setLocaleCode('en'),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase('en');

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
