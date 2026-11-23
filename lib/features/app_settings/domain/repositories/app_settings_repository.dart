import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/app_settings_data_source.dart';

class AppSettingsRepository {
  AppSettingsRepository({AppSettingsDataSource? dataSource})
    : _dataSource = dataSource ?? sl<AppSettingsDataSource>();

  final AppSettingsDataSource _dataSource;

  final _localeCode = signal<String?>(null);
  final _welcomeCompleted = signal<bool>(false);

  /// `null` follows the system language.
  ReadonlySignal<String?> get localeCode => _localeCode;
  ReadonlySignal<bool> get welcomeCompleted => _welcomeCompleted;

  Future<Either<AppError, Unit>> load() async {
    try {
      _localeCode.value = await _dataSource.readLocaleCode();
      _welcomeCompleted.value = await _dataSource.readWelcomeCompleted();
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  Future<Either<AppError, Unit>> setLocaleCode(String? code) async {
    try {
      await _dataSource.writeLocaleCode(code);
      _localeCode.value = code;
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  Future<Either<AppError, Unit>> completeWelcome() async {
    try {
      await _dataSource.writeWelcomeCompleted();
      _welcomeCompleted.value = true;
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }
}
