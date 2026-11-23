import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../view_models/workflow_run_view_model.dart';
import '../widgets/run/workflow_run_actions.dart';
import '../widgets/run/workflow_run_content.dart';
import '../widgets/run/workflow_run_header.dart';

/// The running workflow (`Workflow.dc.html`).
class WorkflowRunScreen extends HookWidget {
  const WorkflowRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<WorkflowRunViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return ColoredBox(
      color: context.kiln.surfaces.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkflowRunHeader(onBack: vm.back, onEdit: vm.edit),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: WorkflowRunContent(vm: vm),
              ),
            ),
            WorkflowRunActions(vm: vm),
          ],
        ),
      ),
    );
  }
}
