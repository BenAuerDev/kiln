import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/scan_repository.dart';

class StopDeviceScanUseCase {
  StopDeviceScanUseCase({ScanRepository? scan})
    : _scan = scan ?? sl<ScanRepository>();

  final ScanRepository _scan;

  Future<Either<AppError, Unit>> call() => _scan.stop();
}
