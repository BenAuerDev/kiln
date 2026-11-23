import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/workflow_editor_view_model.dart';

/// Back, "New workflow" / "Edit workflow" and Save.
class WorkflowEditorHeader extends SignalWidget {
  const WorkflowEditorHeader({required this.vm, super.key});

  final WorkflowEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        spacing: 12,
        children: [
          SizedBox.square(
            dimension: 48,
            child: OiIconButton(
              icon: OiIcons.chevronLeft,
              semanticLabel: l10n.workflowsBack,
              variant: OiButtonVariant.outline,
              onTap: vm.back,
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: OiLabel.h4(
                vm.isExisting.value
                    ? l10n.workflowsEditorEditTitle
                    : l10n.workflowsEditorNewTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          OiButton.primary(
            label: l10n.workflowsEditorSave,
            enabled: vm.canSave.value,
            loading: vm.saving.value,
            onTap: vm.save,
          ),
        ],
      ),
    );
  }
}
