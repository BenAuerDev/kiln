import '../../../../core/service_locator.dart';
import '../repositories/portable_repository.dart';

class StopPortableSessionUseCase {
  StopPortableSessionUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  Future<void> call() => _repository.stopSession();
}
