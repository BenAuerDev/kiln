import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/ramp_run.dart';
import '../repositories/ramp_run_repository.dart';

/// Stops the ramp where it is. The base and the heater stay as they are.
class StopRampUseCase {
  StopRampUseCase({RampRunRepository? runs})
    : _runs = runs ?? sl<RampRunRepository>();

  final RampRunRepository _runs;

  Future<Either<AppError, Unit>> call() => _runs.serialized(() async {
    final run = _runs.run.value;
    if (run != null && run.isActive) {
      _runs.end(run.copyWith(phase: RampRunPhase.stopped));
    }
    return right(unit);
  });
}
