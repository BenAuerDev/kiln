import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/finish_preference.dart';
import '../repositories/known_devices_repository.dart';

/// Stores the app theme chosen for one device.
class SetDeviceFinishUseCase {
  SetDeviceFinishUseCase({KnownDevicesRepository? knownDevices})
    : _knownDevices = knownDevices ?? sl<KnownDevicesRepository>();

  final KnownDevicesRepository _knownDevices;

  Future<Either<AppError, Unit>> call(
    String deviceId,
    FinishPreference preference,
  ) async {
    final device = _knownDevices.byId(deviceId);
    if (device == null) return left(const AppError.deviceNotFound());
    if (device.finishPreference == preference) return right(unit);
    return _knownDevices.save(device.copyWith(finishPreference: preference));
  }
}
