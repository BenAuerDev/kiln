import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../domain/models/workflow_step.dart';
import '../../extensions/workflow_step_x.dart';
import '../../view_models/workflow_editor_view_model.dart';

/// "+ Heat", "+ Hold", "+ Air".
class WorkflowAddStepRow extends SignalWidget {
  const WorkflowAddStepRow({required this.vm, super.key});

  final WorkflowEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final enabled = vm.canAddStep.value;
    return Row(
      spacing: 8,
      children: [
        for (final kind in WorkflowStepKind.values)
          Expanded(
            child: OiButton.outline(
              label: kind.label(l10n),
              icon: OiIcons.plus,
              semanticLabel: l10n.workflowsEditorAddSemantics(kind.label(l10n)),
              fullWidth: true,
              enabled: enabled,
              onTap: () => vm.add(kind),
            ),
          ),
      ],
    );
  }
}
