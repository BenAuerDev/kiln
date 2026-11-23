import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/heater_mode.dart';
import '../repositories/portable_repository.dart';

/// Switches the heater on (normal mode) when it is off, and off from any
/// other mode, boost included (docs/protocol.md, Boost: mode 0 ends boost). Returns
/// the new mode.
class TogglePortableHeaterUseCase {
  TogglePortableHeaterUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  Future<Either<AppError, HeaterMode>> call() async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final next = status.heaterMode == HeaterMode.off
        ? HeaterMode.normal
        : HeaterMode.off;
    return (await _repository.setHeaterMode(next)).map((_) => next);
  }
}
