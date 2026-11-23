import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/workflow_editor_view_model.dart';

class WorkflowHeaterOffSwitch extends SignalWidget {
  const WorkflowHeaterOffSwitch({required this.vm, super.key});

  final WorkflowEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return OiSwitchTile(
      title: l10n.workflowsEditorHeaterOff,
      subtitle: l10n.workflowsEditorHeaterOffHint,
      value: vm.heaterOffAtEnd.value,
      onChanged: vm.setHeaterOffAtEnd,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }
}
