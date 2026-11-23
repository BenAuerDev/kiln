import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/device_model.dart';
import '../repositories/portable_repository.dart';
import 'detect_portable_finish_use_case.dart';

/// Starts the session, then detects the device finish. A failed detection
/// does not fail the start.
class StartPortableSessionUseCase {
  StartPortableSessionUseCase({
    PortableRepository? repository,
    DetectPortableFinishUseCase? detectFinish,
  }) : _repository = repository ?? sl<PortableRepository>(),
       _detectFinish = detectFinish ?? sl<DetectPortableFinishUseCase>();

  final PortableRepository _repository;
  final DetectPortableFinishUseCase _detectFinish;

  Future<Either<AppError, Unit>> call(
    String deviceId,
    DeviceModel model,
  ) async {
    final started = await _repository.startSession(deviceId, model);
    if (started.isRight()) await _detectFinish(deviceId, model);
    return started;
  }
}
