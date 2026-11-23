import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/heater_mode.dart';
import '../repositories/portable_repository.dart';

/// The Boost button: off or normal → boost → superboost → off, then on again
/// at base. Returns the new mode.
class TogglePortableBoostUseCase {
  TogglePortableBoostUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  Future<Either<AppError, HeaterMode>> call() async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final next = switch (status.heaterMode) {
      HeaterMode.off || HeaterMode.normal => HeaterMode.boost,
      HeaterMode.boost => HeaterMode.superboost,
      HeaterMode.superboost => null,
    };
    if (next != null) {
      return (await _repository.setHeaterMode(next)).map((_) => next);
    }
    // Heater mode 1 alone does not end boost (seen on a Veazy and a Venty),
    // but heater off does; for superboost too. Off, then
    // on again at base.
    final off = await _repository.setHeaterMode(HeaterMode.off);
    if (off.isLeft()) return off.map((_) => HeaterMode.off);
    return (await _repository.setHeaterMode(
      HeaterMode.normal,
    )).map((_) => HeaterMode.normal);
  }
}
