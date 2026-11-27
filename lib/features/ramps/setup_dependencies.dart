import '../../core/service_locator.dart';
import 'data/data_sources/ramps_data_source.dart';
import 'domain/repositories/ramp_run_repository.dart';
import 'domain/repositories/ramps_repository.dart';
import 'domain/services/ramp_editing_service.dart';
import 'domain/services/ramp_service.dart';
import 'domain/use_cases/advance_ramp_use_case.dart';
import 'domain/use_cases/delete_ramp_use_case.dart';
import 'domain/use_cases/find_ramp_use_case.dart';
import 'domain/use_cases/load_ramps_use_case.dart';
import 'domain/use_cases/save_ramp_use_case.dart';
import 'domain/use_cases/select_ramp_use_case.dart';
import 'domain/use_cases/start_ramp_use_case.dart';
import 'domain/use_cases/stop_ramp_use_case.dart';
import 'domain/use_cases/toggle_ramp_use_case.dart';
import 'presentation/navigation/ramps_navigator.dart';
import 'presentation/view_models/ramp_editor_view_model.dart';
import 'presentation/view_models/ramp_view_model.dart';

void setupRampsDependencies() {
  sl
    ..registerLazySingleton(
      RampRunRepository.new,
      dispose: (repository) => repository.clear(),
    )
    ..registerLazySingleton(RampService.new)
    ..registerLazySingleton(RampEditingService.new)
    ..registerLazySingleton(() => RampsDataSource(sl()))
    ..registerLazySingleton(RampsRepository.new)
    ..registerLazySingleton(RampsNavigator.new)
    ..registerFactory(LoadRampsUseCase.new)
    ..registerFactory(FindRampUseCase.new)
    ..registerFactory(SaveRampUseCase.new)
    ..registerFactory(DeleteRampUseCase.new)
    ..registerFactory(SelectRampUseCase.new)
    ..registerFactory(AdvanceRampUseCase.new)
    ..registerFactory(StartRampUseCase.new)
    ..registerFactory(StopRampUseCase.new)
    ..registerFactory(ToggleRampUseCase.new)
    ..registerFactory(RampViewModel.new)
    ..registerFactoryParam<RampEditorViewModel, String?, String?>(
      (id, from) => RampEditorViewModel(rampId: id, fromId: from),
    );
}
