import '../../core/service_locator.dart';
import 'domain/repositories/ramp_run_repository.dart';
import 'domain/services/ramp_service.dart';
import 'domain/use_cases/advance_ramp_use_case.dart';
import 'domain/use_cases/start_ramp_use_case.dart';
import 'domain/use_cases/stop_ramp_use_case.dart';
import 'presentation/view_models/ramp_view_model.dart';

void setupRampsDependencies() {
  sl
    ..registerLazySingleton(
      RampRunRepository.new,
      dispose: (repository) => repository.clear(),
    )
    ..registerLazySingleton(RampService.new)
    ..registerFactory(AdvanceRampUseCase.new)
    ..registerFactory(StartRampUseCase.new)
    ..registerFactory(StopRampUseCase.new)
    ..registerFactory(RampViewModel.new);
}
