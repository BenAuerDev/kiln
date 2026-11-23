import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../domain/models/workflow.dart';
import '../../extensions/workflow_x.dart';
import '../../view_models/workflows_view_model.dart';
import 'workflow_card.dart';

/// One [WorkflowCard] per workflow, with Start and edit wired to [vm].
class WorkflowCardList extends SignalWidget {
  const WorkflowCardList({
    required this.vm,
    required this.workflows,
    super.key,
  });

  final WorkflowsViewModel vm;
  final List<Workflow> workflows;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final starting = vm.startingId.value;
    final canStart = vm.canStart.value && starting == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (final workflow in workflows)
          WorkflowCard(
            key: ValueKey(workflow.id),
            name: workflow.displayName(l10n),
            summary: vm.summaryOf(workflow),
            starting: starting == workflow.id,
            canStart: canStart,
            onStart: () => vm.start(workflow),
            onEdit: () => vm.edit(workflow),
          ),
      ],
    );
  }
}
