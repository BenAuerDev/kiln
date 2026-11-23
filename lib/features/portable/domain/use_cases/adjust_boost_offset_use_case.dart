import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/portable_repository.dart';
import '../services/portable_temperature_limits.dart';

class AdjustBoostOffsetUseCase {
  AdjustBoostOffsetUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  /// Moves the boost offset by [delta] within 1–30 °C. Returns the
  /// written value, or `none()` when it would not change.
  Future<Either<AppError, Option<int>>> call(int delta) async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final next = PortableTemperatureLimits.step(
      status.boostOffset,
      delta,
      min: PortableTemperatureLimits.minOffset,
      max: PortableTemperatureLimits.maxOffset,
    );
    return switch (next) {
      None() => right(none()),
      Some(:final value) => (await _repository.setBoostOffset(
        value,
      )).map((_) => some(value)),
    };
  }
}
