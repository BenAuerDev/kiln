import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/device_finish.dart';
import '../repositories/known_devices_repository.dart';

/// Records the finish read from the device itself, which "Match my device"
/// follows. See `FinishDetectionService` for how to get one.
class SetDetectedFinishUseCase {
  SetDetectedFinishUseCase({KnownDevicesRepository? knownDevices})
    : _knownDevices = knownDevices ?? sl<KnownDevicesRepository>();

  final KnownDevicesRepository _knownDevices;

  Future<Either<AppError, Unit>> call(
    String deviceId,
    DeviceFinish finish,
  ) async {
    final device = _knownDevices.byId(deviceId);
    if (device == null) return left(const AppError.deviceNotFound());
    if (device.detectedFinish == finish) return right(unit);
    return _knownDevices.save(device.copyWith(detectedFinish: finish));
  }
}
