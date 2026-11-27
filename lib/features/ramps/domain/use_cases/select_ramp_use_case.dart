import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/ramps_repository.dart';

/// Chooses the ramp the card and widget start, and keeps the choice across
/// restarts.
class SelectRampUseCase {
  SelectRampUseCase({RampsRepository? repository})
    : _repository = repository ?? sl<RampsRepository>();

  final RampsRepository _repository;

  Future<Either<AppError, Unit>> call(String id) => _repository.select(id);
}
