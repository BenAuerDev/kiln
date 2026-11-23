import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/volcano_repository.dart';

class StopVolcanoSessionUseCase {
  StopVolcanoSessionUseCase({VolcanoRepository? repository})
    : _repository = repository ?? sl<VolcanoRepository>();

  final VolcanoRepository _repository;

  Future<Either<AppError, Unit>> call() => _repository.stopSession();
}
