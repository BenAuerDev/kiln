import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/workflow_editor_view_model.dart';

/// Delete, with a second tap to confirm. Only for saved user workflows.
class WorkflowDeleteButton extends SignalWidget {
  const WorkflowDeleteButton({required this.vm, super.key});

  final WorkflowEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.isExisting.value) return const SizedBox.shrink();
    final l10n = getAppLocalizations(context);
    return OiButton.destructive(
      label: vm.confirmingDelete.value
          ? l10n.workflowsEditorDeleteConfirm
          : l10n.workflowsEditorDelete,
      icon: OiIcons.trash2,
      fullWidth: true,
      onTap: vm.delete,
    );
  }
}
