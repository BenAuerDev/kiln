import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:kiln/features/app_settings/domain/use_cases/complete_welcome_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

void main() {
  late MockAppSettingsRepository repository;
  late CompleteWelcomeUseCase useCase;

  setUp(() {
    repository = MockAppSettingsRepository();
    useCase = CompleteWelcomeUseCase(repository: repository);
  });

  test('marks the welcome as completed', () async {
    when(
      () => repository.completeWelcome(),
    ).thenAnswer((_) async => right(unit));

    expect((await useCase()).isRight(), isTrue);
    verify(() => repository.completeWelcome()).called(1);
  });

  test('passes storage errors through', () async {
    when(
      () => repository.completeWelcome(),
    ).thenAnswer((_) async => left(const AppError.storage()));

    expect((await useCase()).getLeft().toNullable(), isA<StorageError>());
  });
}
