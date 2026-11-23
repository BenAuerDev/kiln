import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/portable_repository.dart';
import '../services/portable_temperature_limits.dart';

class AdjustBaseTemperatureUseCase {
  AdjustBaseTemperatureUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  /// Moves the base temperature by [delta] within 40–210 °C. Returns the
  /// written value, or `none()` when it would not change.
  Future<Either<AppError, Option<int>>> call(int delta) async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final next = PortableTemperatureLimits.step(
      status.targetTemperature,
      delta,
      min: PortableTemperatureLimits.minTemperature,
      max: PortableTemperatureLimits.maxTemperature,
    );
    return switch (next) {
      None() => right(none()),
      Some(:final value) => (await _repository.setTargetTemperature(
        value,
      )).map((_) => some(value)),
    };
  }
}
