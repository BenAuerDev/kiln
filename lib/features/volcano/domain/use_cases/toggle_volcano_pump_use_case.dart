import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/volcano_repository.dart';

/// Switches the air pump to the opposite of its current state and returns the
/// new state.
class ToggleVolcanoPumpUseCase {
  ToggleVolcanoPumpUseCase({VolcanoRepository? repository})
    : _repository = repository ?? sl<VolcanoRepository>();

  final VolcanoRepository _repository;

  Future<Either<AppError, bool>> call() async {
    final status = _repository.status.value;
    if (status == null) return left(const AppError.notConnected());
    final on = !status.pumpOn;
    return (await _repository.setPump(on)).map((_) => on);
  }
}
