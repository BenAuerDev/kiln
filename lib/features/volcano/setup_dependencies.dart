import '../../core/service_locator.dart';
import 'data/data_sources/volcano_ble_data_source.dart';
import 'domain/repositories/volcano_repository.dart';
import 'domain/use_cases/adjust_volcano_target_use_case.dart';
import 'domain/use_cases/set_volcano_target_use_case.dart';
import 'domain/use_cases/start_volcano_session_use_case.dart';
import 'domain/use_cases/stop_volcano_session_use_case.dart';
import 'domain/use_cases/toggle_volcano_heater_use_case.dart';
import 'domain/use_cases/toggle_volcano_pump_use_case.dart';
import 'presentation/navigation/volcano_navigator.dart';
import 'presentation/view_models/volcano_control_view_model.dart';

void setupVolcanoDependencies() {
  sl
    ..registerLazySingleton(() => VolcanoBleDataSource(sl()))
    ..registerLazySingleton(VolcanoRepository.new)
    ..registerFactory(StartVolcanoSessionUseCase.new)
    ..registerFactory(StopVolcanoSessionUseCase.new)
    ..registerFactory(SetVolcanoTargetUseCase.new)
    ..registerFactory(AdjustVolcanoTargetUseCase.new)
    ..registerFactory(ToggleVolcanoHeaterUseCase.new)
    ..registerFactory(ToggleVolcanoPumpUseCase.new)
    ..registerLazySingleton(VolcanoNavigator.new)
    ..registerFactory(VolcanoControlViewModel.new);
}
