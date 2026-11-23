import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../../devices/presentation/widgets/common/section_label.dart';
import '../../view_models/workflows_view_model.dart';
import 'workflow_card_list.dart';

/// Presets, then the user's workflows and "New workflow".
class WorkflowsLists extends SignalWidget {
  const WorkflowsLists({required this.vm, super.key});

  final WorkflowsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final user = vm.userWorkflows.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionLabel(l10n.workflowsPresets),
        WorkflowCardList(vm: vm, workflows: vm.presets),
        const SizedBox(height: 8),
        SectionLabel(l10n.workflowsYours),
        if (user.isEmpty)
          OiLabel.small(
            l10n.workflowsNoneYet,
            color: context.kiln.surfaces.muted,
          ),
        if (user.isNotEmpty) WorkflowCardList(vm: vm, workflows: user),
        OiButton.outline(
          label: l10n.workflowsNew,
          icon: OiIcons.plus,
          fullWidth: true,
          onTap: vm.create,
        ),
      ],
    );
  }
}
