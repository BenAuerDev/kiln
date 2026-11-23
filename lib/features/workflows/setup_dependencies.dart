import '../../core/service_locator.dart';
import 'data/data_sources/workflows_data_source.dart';
import 'domain/repositories/workflow_run_repository.dart';
import 'domain/repositories/workflows_repository.dart';
import 'domain/services/workflow_editing_service.dart';
import 'domain/services/workflow_step_service.dart';
import 'domain/use_cases/advance_workflow_run_use_case.dart';
import 'domain/use_cases/delete_workflow_use_case.dart';
import 'domain/use_cases/dismiss_workflow_run_use_case.dart';
import 'domain/use_cases/find_workflow_use_case.dart';
import 'domain/use_cases/load_workflows_use_case.dart';
import 'domain/use_cases/save_workflow_use_case.dart';
import 'domain/use_cases/skip_workflow_step_use_case.dart';
import 'domain/use_cases/start_workflow_run_use_case.dart';
import 'domain/use_cases/stop_workflow_run_use_case.dart';
import 'presentation/navigation/workflows_navigator.dart';
import 'presentation/view_models/workflow_editor_view_model.dart';
import 'presentation/view_models/workflow_run_banner_view_model.dart';
import 'presentation/view_models/workflow_run_view_model.dart';
import 'presentation/view_models/workflows_view_model.dart';

void setupWorkflowsDependencies() {
  sl
    ..registerLazySingleton(() => WorkflowsDataSource(sl()))
    ..registerLazySingleton(WorkflowsRepository.new)
    ..registerLazySingleton(
      WorkflowRunRepository.new,
      dispose: (repository) => repository.clear(),
    )
    ..registerLazySingleton(WorkflowStepService.new)
    ..registerLazySingleton(WorkflowEditingService.new)
    ..registerLazySingleton(WorkflowsNavigator.new)
    ..registerFactory(LoadWorkflowsUseCase.new)
    ..registerFactory(FindWorkflowUseCase.new)
    ..registerFactory(SaveWorkflowUseCase.new)
    ..registerFactory(DeleteWorkflowUseCase.new)
    ..registerFactory(AdvanceWorkflowRunUseCase.new)
    ..registerFactory(StartWorkflowRunUseCase.new)
    ..registerFactory(SkipWorkflowStepUseCase.new)
    ..registerFactory(StopWorkflowRunUseCase.new)
    ..registerFactory(DismissWorkflowRunUseCase.new)
    ..registerFactory(WorkflowsViewModel.new)
    ..registerFactory(WorkflowRunViewModel.new)
    ..registerFactory(WorkflowRunBannerViewModel.new)
    ..registerFactoryParam<WorkflowEditorViewModel, String?, void>(
      (id, _) => WorkflowEditorViewModel(workflowId: id),
    );
}
