import '../../../../core/service_locator.dart';
import '../repositories/portable_repository.dart';

/// Pauses the Venty/Veazy status poll while the app is in the background and
/// resumes it when the app is visible again.
class SetPortablePollingUseCase {
  SetPortablePollingUseCase({PortableRepository? repository})
    : _repository = repository ?? sl<PortableRepository>();

  final PortableRepository _repository;

  void call({required bool active}) =>
      active ? _repository.resumePolling() : _repository.pausePolling();
}
