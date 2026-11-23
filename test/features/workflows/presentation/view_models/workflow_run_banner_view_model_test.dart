import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/presentation/view_models/workflow_run_banner_view_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  test('shows the active run only, and Open goes to it', () {
    final runs = WorkflowRunRepository();
    final navigator = MockWorkflowsNavigator();
    final vm = WorkflowRunBannerViewModel(
      runs: runs,
      l10n: FakeL10nService(),
      navigator: navigator,
    );
    expect(vm.activeRun.value, isNull);

    final run = WorkflowRun(
      deviceId: 'v',
      workflow: WorkflowPresets.all.first,
      stepIndex: 1,
      stepStartedAt: DateTime(2026),
    );
    runs.update(run);
    expect(vm.name.value, 'Three-balloon session');
    expect(vm.headline.value, 'Step 2 of 6 · Air');

    runs.end(run.copyWith(phase: WorkflowRunPhase.stopped));
    expect(vm.activeRun.value, isNull);

    vm.open();
    verify(() => navigator.openRun()).called(1);
    vm.dispose();
  });
}
