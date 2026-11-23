import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../repositories/portable_repository.dart';

class FindPortableDeviceUseCase {
  FindPortableDeviceUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  Future<Either<AppError, Unit>> call() async {
    if (_repository.status.value == null) {
      return left(const AppError.notConnected());
    }
    return _repository.findDevice();
  }
}
