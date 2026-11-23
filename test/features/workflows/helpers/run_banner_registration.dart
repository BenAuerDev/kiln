import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflow_run_banner_view_model.dart';

import '../mocks.dart';

/// Registers the view model of the "Running now" banner that the Volcano
/// screens show; hidden unless [runs] holds an active run.
void registerRunBanner({WorkflowRunRepository? runs}) => sl.registerFactory(
  () => WorkflowRunBannerViewModel(
    runs: runs ?? WorkflowRunRepository(),
    l10n: FakeL10nService(),
    navigator: MockWorkflowsNavigator(),
  ),
);
