import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/scan_repository.dart';

/// Scans for Storz & Bickel devices. Results land in `ScanRepository.results`.
class StartDeviceScanUseCase {
  StartDeviceScanUseCase({ScanRepository? scan})
    : _scan = scan ?? sl<ScanRepository>();

  final ScanRepository _scan;

  Future<Either<AppError, Unit>> call() => _scan.start();
}
