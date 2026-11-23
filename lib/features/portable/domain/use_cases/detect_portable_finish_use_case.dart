import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/device_finish.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/services/finish_detection_service.dart';
import '../../../devices/domain/use_cases/set_detected_finish_use_case.dart';
import '../repositories/portable_repository.dart';

/// Reads the body colour of a Veazy and records it for "Match my device".
/// Other models report no reliable colour, so nothing is read for them.
class DetectPortableFinishUseCase {
  DetectPortableFinishUseCase({
    PortableRepository? repository,
    FinishDetectionService? detection,
    SetDetectedFinishUseCase? setDetectedFinish,
  }) : _repository = repository ?? sl<PortableRepository>(),
       _detection = detection ?? sl<FinishDetectionService>(),
       _setDetectedFinish = setDetectedFinish ?? sl<SetDetectedFinishUseCase>();

  final PortableRepository _repository;
  final FinishDetectionService _detection;
  final SetDetectedFinishUseCase _setDetectedFinish;

  Future<Either<AppError, Option<DeviceFinish>>> call(
    String deviceId,
    DeviceModel model,
  ) async {
    if (model != DeviceModel.veazy) return right(none());
    final index = await _repository.readColorIndex();
    return index.match((error) async => left(error), (index) async {
      if (index.isNone()) return right(none());
      final finish = _detection.fromVeazyColorIndex(index.toNullable()!);
      final saved = await _setDetectedFinish(deviceId, finish);
      return saved.map((_) => some(finish));
    });
  }
}
