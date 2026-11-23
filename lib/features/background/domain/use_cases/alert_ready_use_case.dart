import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/background_notice.dart';
import '../repositories/background_service_repository.dart';

/// The "ready" alert (`Live.dc.html`, Android notification).
class AlertReadyUseCase {
  AlertReadyUseCase({BackgroundServiceRepository? repository})
    : _repository = repository ?? sl<BackgroundServiceRepository>();

  final BackgroundServiceRepository _repository;

  Future<Either<AppError, Unit>> call(BackgroundNotice notice) =>
      _repository.alert(notice);
}
