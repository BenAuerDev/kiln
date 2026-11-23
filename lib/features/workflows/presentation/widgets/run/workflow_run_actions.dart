import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/workflow_run_view_model.dart';

/// Skip / Stop while running; Run again / Done afterwards.
class WorkflowRunActions extends SignalWidget {
  const WorkflowRunActions({required this.vm, super.key});

  final WorkflowRunViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final run = vm.run.value;
    if (run == null) return const SizedBox.shrink();
    final active = run.isActive;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: OiButton.outline(
              label: active ? l10n.workflowsSkip : l10n.workflowsRunAgain,
              size: OiButtonSize.large,
              fullWidth: true,
              enabled: active ? !vm.skipping.value : vm.canRunAgain.value,
              onTap: active ? vm.skip : vm.runAgain,
            ),
          ),
          Expanded(
            child: OiButton.primary(
              label: active ? l10n.workflowsStop : l10n.workflowsDone,
              size: OiButtonSize.large,
              fullWidth: true,
              onTap: active ? vm.stop : vm.done,
            ),
          ),
        ],
      ),
    );
  }
}
