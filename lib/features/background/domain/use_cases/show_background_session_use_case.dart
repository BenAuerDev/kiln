import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/background_notice.dart';
import '../repositories/background_service_repository.dart';

/// Runs the background service with [notice] while a device heats, and
/// stops it (`null`) when nothing does.
class ShowBackgroundSessionUseCase {
  ShowBackgroundSessionUseCase({BackgroundServiceRepository? repository})
    : _repository = repository ?? sl<BackgroundServiceRepository>();

  final BackgroundServiceRepository _repository;

  Future<Either<AppError, Unit>> call(BackgroundNotice? notice) =>
      notice == null ? _repository.hide() : _repository.show(notice);
}
