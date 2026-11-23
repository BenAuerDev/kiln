import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../extensions/workflow_step_x.dart';
import '../../view_models/workflow_editor_view_model.dart';
import 'workflow_step_editor_row.dart';

/// The steps of the draft, or a hint while there are none.
class WorkflowStepEditorList extends SignalWidget {
  const WorkflowStepEditorList({required this.vm, super.key});

  final WorkflowEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final steps = vm.steps.value;
    if (steps.isEmpty) {
      return OiLabel.small(
        l10n.workflowsEditorNoSteps,
        color: context.kiln.surfaces.muted,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (var i = 0; i < steps.length; i++)
          WorkflowStepEditorRow(
            number: i + 1,
            title: steps[i].title(l10n),
            icon: steps[i].kind.icon,
            onLower: () => vm.lower(i),
            onRaise: () => vm.raise(i),
            onRemove: () => vm.remove(i),
            onMoveUp: i == 0 ? null : () => vm.moveUp(i),
            onMoveDown: i == steps.length - 1 ? null : () => vm.moveDown(i),
          ),
      ],
    );
  }
}
