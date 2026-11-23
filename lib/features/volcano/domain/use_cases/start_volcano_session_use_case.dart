import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../repositories/volcano_repository.dart';

class StartVolcanoSessionUseCase {
  StartVolcanoSessionUseCase({
    VolcanoRepository? repository,
    KnownDevicesRepository? knownDevices,
  }) : _repository = repository ?? sl<VolcanoRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>();

  final VolcanoRepository _repository;
  final KnownDevicesRepository _knownDevices;

  /// Returns [NotConnectedError] without touching BLE when the device is not
  /// a known Volcano Hybrid.
  Future<Either<AppError, Unit>> call(String deviceId) async {
    if (_knownDevices.byId(deviceId)?.model != DeviceModel.volcanoHybrid) {
      return left(const AppError.notConnected());
    }
    return _repository.startSession(deviceId);
  }
}
