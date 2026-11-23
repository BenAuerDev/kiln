import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/haptics_service.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/domain/repositories/volcano_repository.dart';
import 'package:kiln/features/volcano/presentation/navigation/volcano_navigator.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_session_sync.dart';
import 'package:kiln/features/workflows/data/data_sources/workflows_data_source.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/repositories/workflows_repository.dart';
import 'package:kiln/features/workflows/domain/use_cases/advance_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/delete_workflow_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/dismiss_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/load_workflows_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/save_workflow_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/skip_workflow_step_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/start_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/stop_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/presentation/navigation/workflows_navigator.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockWorkflowsDataSource extends Mock implements WorkflowsDataSource {}

class MockWorkflowsRepository extends Mock implements WorkflowsRepository {}

class MockWorkflowRunRepository extends Mock implements WorkflowRunRepository {}

class MockVolcanoRepository extends Mock implements VolcanoRepository {}

class MockAdvanceWorkflowRunUseCase extends Mock
    implements AdvanceWorkflowRunUseCase {}

class MockStartWorkflowRunUseCase extends Mock
    implements StartWorkflowRunUseCase {}

class MockSkipWorkflowStepUseCase extends Mock
    implements SkipWorkflowStepUseCase {}

class MockStopWorkflowRunUseCase extends Mock
    implements StopWorkflowRunUseCase {}

class MockDismissWorkflowRunUseCase extends Mock
    implements DismissWorkflowRunUseCase {}

class MockLoadWorkflowsUseCase extends Mock implements LoadWorkflowsUseCase {}

class MockSaveWorkflowUseCase extends Mock implements SaveWorkflowUseCase {}

class MockDeleteWorkflowUseCase extends Mock implements DeleteWorkflowUseCase {}

class MockWorkflowsNavigator extends Mock implements WorkflowsNavigator {}

class MockVolcanoNavigator extends Mock implements VolcanoNavigator {}

class MockVolcanoSessionSync extends Mock implements VolcanoSessionSync {}

class MockHapticsService extends Mock implements HapticsService {}

class MockToastService extends Mock implements ToastService {}

class FakeL10nService extends L10nService {}

VolcanoStatus volcanoStatus({
  double? current = 23,
  int target = 170,
  bool heaterOn = false,
  bool pumpOn = false,
}) => VolcanoStatus(
  currentTemperature: current,
  targetTemperature: target,
  heaterOn: heaterOn,
  pumpOn: pumpOn,
  autoShutdown: true,
  fahrenheit: false,
  displayOnCooling: true,
  vibrationWhenReady: true,
);
