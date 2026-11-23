import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/portable_settings.dart';
import '../repositories/portable_repository.dart';

class UpdatePortableSettingsUseCase {
  UpdatePortableSettingsUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  /// Does nothing when the device already has [settings].
  Future<Either<AppError, Unit>> call(PortableSettings settings) async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    if (status.settings == settings) return right(unit);
    return _repository.setSettings(settings);
  }
}
