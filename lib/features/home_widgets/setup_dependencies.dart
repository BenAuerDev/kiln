import '../../core/service_locator.dart';
import 'data/data_sources/home_widget_data_source.dart';
import 'domain/repositories/home_widgets_repository.dart';
import 'domain/services/home_widget_snapshot_service.dart';
import 'domain/use_cases/current_portable_widget_use_case.dart';
import 'domain/use_cases/current_volcano_widget_use_case.dart';
import 'domain/use_cases/handle_home_widget_action_use_case.dart';
import 'domain/use_cases/show_portable_widget_use_case.dart';
import 'domain/use_cases/show_volcano_widget_use_case.dart';
import 'domain/use_cases/listen_to_home_widget_actions_use_case.dart';
import 'presentation/view_models/home_widgets_view_model.dart';

void setupHomeWidgetsDependencies() {
  sl
    ..registerLazySingleton(HomeWidgetDataSource.new)
    ..registerLazySingleton(HomeWidgetsRepository.new)
    ..registerLazySingleton(() => HomeWidgetSnapshotService(sl()))
    ..registerFactory(CurrentPortableWidgetUseCase.new)
    ..registerFactory(CurrentVolcanoWidgetUseCase.new)
    ..registerFactory(ShowPortableWidgetUseCase.new)
    ..registerFactory(ShowVolcanoWidgetUseCase.new)
    ..registerFactory(ListenToHomeWidgetActionsUseCase.new)
    ..registerFactory(HandleHomeWidgetActionUseCase.new)
    ..registerFactory(HomeWidgetsViewModel.new);
}
