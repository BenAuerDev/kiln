import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/volcano_repository.dart';
import '../services/volcano_target_rules.dart';

/// Sets the target, clamped to 40–230 °C. Returns the written value, or
/// `none()` when it already matches the device (nothing is written).
class SetVolcanoTargetUseCase {
  SetVolcanoTargetUseCase({VolcanoRepository? repository})
    : _repository = repository ?? sl<VolcanoRepository>();

  final VolcanoRepository _repository;

  Future<Either<AppError, Option<int>>> call(int celsius) async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final next = VolcanoTargetRules.next(
      current: status.targetTemperature,
      requested: celsius,
    );
    return switch (next) {
      None() => right(const None()),
      Some(:final value) => (await _repository.setTargetTemperature(
        value,
      )).map((_) => Some(value)),
    };
  }
}
