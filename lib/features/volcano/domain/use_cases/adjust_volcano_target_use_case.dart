import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/volcano_repository.dart';
import '../services/volcano_target_rules.dart';

/// Moves the target by [delta] °C, clamped to 40–230 °C. Returns the written
/// value, or `none()` when the clamp leaves it unchanged (nothing is written).
class AdjustVolcanoTargetUseCase {
  AdjustVolcanoTargetUseCase({VolcanoRepository? repository})
    : _repository = repository ?? sl<VolcanoRepository>();

  final VolcanoRepository _repository;

  Future<Either<AppError, Option<int>>> call(int delta) async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final next = VolcanoTargetRules.next(
      current: status.targetTemperature,
      requested: status.targetTemperature + delta,
    );
    return switch (next) {
      None() => right(const None()),
      Some(:final value) => (await _repository.setTargetTemperature(
        value,
      )).map((_) => Some(value)),
    };
  }
}
