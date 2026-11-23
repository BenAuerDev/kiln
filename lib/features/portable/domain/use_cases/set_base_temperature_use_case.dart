import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/portable_repository.dart';
import '../services/portable_temperature_limits.dart';

class SetBaseTemperatureUseCase {
  SetBaseTemperatureUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  /// Clamps to 40–210 °C. Returns the written value, or `none()` when the
  /// device already has it (nothing is written).
  Future<Either<AppError, Option<int>>> call(int celsius) async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final target = PortableTemperatureLimits.clampTemperature(celsius);
    if (target == status.targetTemperature) return right(none());
    final result = await _repository.setTargetTemperature(target);
    return result.map((_) => some(target));
  }
}
