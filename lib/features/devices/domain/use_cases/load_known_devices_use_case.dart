import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/known_devices_repository.dart';

class LoadKnownDevicesUseCase {
  LoadKnownDevicesUseCase({KnownDevicesRepository? knownDevices})
    : _knownDevices = knownDevices ?? sl<KnownDevicesRepository>();

  final KnownDevicesRepository _knownDevices;

  Future<Either<AppError, Unit>> call() => _knownDevices.load();
}
