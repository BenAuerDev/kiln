import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/app_settings/data/data_sources/app_settings_data_source.dart';
import 'package:kiln/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsDataSource extends Mock implements AppSettingsDataSource {}

void main() {
  late MockAppSettingsDataSource dataSource;
  late AppSettingsRepository repository;

  setUp(() {
    dataSource = MockAppSettingsDataSource();
    repository = AppSettingsRepository(dataSource: dataSource);
  });

  group('load', () {
    test('fills the signals from storage', () async {
      when(() => dataSource.readLocaleCode()).thenAnswer((_) async => 'de');
      when(
        () => dataSource.readWelcomeCompleted(),
      ).thenAnswer((_) async => true);

      final result = await repository.load();

      expect(result, right<AppError, Unit>(unit));
      expect(repository.localeCode.value, 'de');
      expect(repository.welcomeCompleted.value, isTrue);
    });

    test('returns a storage error when reading fails', () async {
      when(() => dataSource.readLocaleCode()).thenThrow(Exception('io'));

      final result = await repository.load();

      expect(result.getLeft().toNullable(), isA<StorageError>());
      expect(repository.welcomeCompleted.value, isFalse);
    });
  });

  group('setLocaleCode', () {
    test('persists and updates the signal', () async {
      when(() => dataSource.writeLocaleCode('en')).thenAnswer((_) async {});

      final result = await repository.setLocaleCode('en');

      expect(result.isRight(), isTrue);
      expect(repository.localeCode.value, 'en');
    });

    test('keeps the old value when writing fails', () async {
      when(() => dataSource.writeLocaleCode('en')).thenThrow(Exception('io'));

      final result = await repository.setLocaleCode('en');

      expect(result.getLeft().toNullable(), isA<StorageError>());
      expect(repository.localeCode.value, isNull);
    });
  });

  group('completeWelcome', () {
    test('persists and updates the signal', () async {
      when(() => dataSource.writeWelcomeCompleted()).thenAnswer((_) async {});

      final result = await repository.completeWelcome();

      expect(result.isRight(), isTrue);
      expect(repository.welcomeCompleted.value, isTrue);
    });

    test('returns a storage error when writing fails', () async {
      when(() => dataSource.writeWelcomeCompleted()).thenThrow(Exception('io'));

      final result = await repository.completeWelcome();

      expect(result.getLeft().toNullable(), isA<StorageError>());
      expect(repository.welcomeCompleted.value, isFalse);
    });
  });
}
