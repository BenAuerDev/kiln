import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/ramp_run_repository.dart';
import '../repositories/ramps_repository.dart';
import '../services/ramp_service.dart';
import 'find_ramp_use_case.dart';
import 'start_ramp_use_case.dart';
import 'stop_ramp_use_case.dart';

/// One button for a ramp (home-screen widget): stops the running ramp, or
/// starts the chosen one (the default preset once it was deleted).
class ToggleRampUseCase {
  ToggleRampUseCase({
    RampRunRepository? runs,
    RampsRepository? userRamps,
    FindRampUseCase? findRamp,
    StartRampUseCase? startRamp,
    StopRampUseCase? stopRamp,
  }) : _runs = runs ?? sl<RampRunRepository>(),
       _userRamps = userRamps ?? sl<RampsRepository>(),
       _findRamp = findRamp ?? sl<FindRampUseCase>(),
       _startRamp = startRamp ?? sl<StartRampUseCase>(),
       _stopRamp = stopRamp ?? sl<StopRampUseCase>();

  final RampRunRepository _runs;
  final RampsRepository _userRamps;
  final FindRampUseCase _findRamp;
  final StartRampUseCase _startRamp;
  final StopRampUseCase _stopRamp;

  Future<Either<AppError, Unit>> call() {
    if (_runs.run.value?.isActive ?? false) return _stopRamp();
    final chosen = _findRamp(_userRamps.selectedId.value).toNullable();
    return _startRamp(chosen ?? RampService.defaultPreset);
  }
}
