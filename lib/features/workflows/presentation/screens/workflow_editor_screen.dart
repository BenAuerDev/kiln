import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../../../devices/presentation/widgets/common/section_label.dart';
import '../view_models/workflow_editor_view_model.dart';
import '../widgets/editor/workflow_add_step_row.dart';
import '../widgets/editor/workflow_delete_button.dart';
import '../widgets/editor/workflow_editor_header.dart';
import '../widgets/editor/workflow_heater_off_switch.dart';
import '../widgets/editor/workflow_name_field.dart';
import '../widgets/editor/workflow_step_editor_list.dart';

/// Creates or edits a workflow. [workflowId] is a user workflow to edit or a
/// preset to copy; `null` starts empty.
class WorkflowEditorScreen extends HookWidget {
  const WorkflowEditorScreen({this.workflowId, super.key});

  final String? workflowId;

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(
      () => sl<WorkflowEditorViewModel>(param1: workflowId),
      [workflowId],
    );
    useEffect(() => vm.dispose, [vm]);
    final l10n = getAppLocalizations(context);
    return ColoredBox(
      color: context.kiln.surfaces.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkflowEditorHeader(vm: vm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    WorkflowNameField(vm: vm),
                    SectionLabel(l10n.workflowsEditorSteps),
                    WorkflowStepEditorList(vm: vm),
                    WorkflowAddStepRow(vm: vm),
                    WorkflowHeaterOffSwitch(vm: vm),
                    WorkflowDeleteButton(vm: vm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
