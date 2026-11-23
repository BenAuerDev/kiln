import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/quick_setup.dart';
import '../repositories/portable_repository.dart';
import '../services/portable_temperature_limits.dart';

class ApplyQuickSetupUseCase {
  ApplyQuickSetupUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  /// Writes base, boost and superboost of [setup], skipping values the
  /// device already has. Stops at the first error.
  Future<Either<AppError, Unit>> call(QuickSetup setup) async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final base = PortableTemperatureLimits.clampTemperature(setup.base);
    final boost = PortableTemperatureLimits.clampOffset(setup.boost);
    final superBoost = PortableTemperatureLimits.clampOffset(setup.superBoost);
    final writes = <Future<Either<AppError, Unit>> Function()>[
      if (status.targetTemperature != base)
        () => _repository.setTargetTemperature(base),
      if (status.boostOffset != boost) () => _repository.setBoostOffset(boost),
      if (status.superBoostOffset != superBoost)
        () => _repository.setSuperBoostOffset(superBoost),
    ];
    for (final write in writes) {
      final result = await write();
      if (result.isLeft()) return result;
    }
    return right(unit);
  }
}
