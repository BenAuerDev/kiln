import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../../../volcano/presentation/view_models/volcano_tab.dart';
import '../../../volcano/presentation/widgets/volcano_bottom_bar.dart';
import '../view_models/workflows_view_model.dart';
import '../widgets/common/workflow_run_banner.dart';
import '../widgets/list/workflows_header.dart';
import '../widgets/list/workflows_lists.dart';

/// The Volcano's Workflows tab.
class WorkflowsScreen extends HookWidget {
  const WorkflowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<WorkflowsViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return ColoredBox(
      color: context.kiln.surfaces.background,
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 20,
                  children: [
                    const WorkflowsHeader(),
                    const WorkflowRunBanner(),
                    WorkflowsLists(vm: vm),
                  ],
                ),
              ),
            ),
          ),
          VolcanoBottomBar(
            current: VolcanoTab.workflows,
            onSelect: vm.selectTab,
          ),
        ],
      ),
    );
  }
}
