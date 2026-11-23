import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../extensions/portable_status_x.dart';
import '../models/heater_mode.dart';
import '../repositories/portable_repository.dart';

/// Starts boost, or ends a running boost or superboost. Returns the new mode.
class TogglePortableBoostUseCase {
  TogglePortableBoostUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  Future<Either<AppError, HeaterMode>> call() async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    if (status.boostActive) {
      // Heater mode 1 alone does not end boost (seen on a Veazy and a Venty),
      // but heater off does. Off, then on again at base.
      final off = await _repository.setHeaterMode(HeaterMode.off);
      if (off.isLeft()) return off.map((_) => HeaterMode.off);
      return (await _repository.setHeaterMode(
        HeaterMode.normal,
      )).map((_) => HeaterMode.normal);
    }
    return (await _repository.setHeaterMode(
      HeaterMode.boost,
    )).map((_) => HeaterMode.boost);
  }
}
