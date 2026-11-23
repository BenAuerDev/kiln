import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/formatters/duration_formatter.dart';
import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../extensions/workflow_run_x.dart';
import '../../extensions/workflow_step_state_x.dart';
import '../../extensions/workflow_step_x.dart';
import '../../extensions/workflow_timeline_entry_x.dart';
import '../../extensions/workflow_x.dart';
import '../../view_models/workflow_run_view_model.dart';
import 'workflow_progress_card.dart';
import 'workflow_timeline_row.dart';

/// Name, summary, progress card and the step timeline.
class WorkflowRunContent extends SignalWidget {
  const WorkflowRunContent({required this.vm, super.key});

  final WorkflowRunViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final muted = context.kiln.surfaces.muted;
    final run = vm.run.value;
    if (run == null) return OiLabel.body(l10n.workflowsNoRun, color: muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: OiLabel.h2(run.workflow.displayName(l10n)),
        ),
        const SizedBox(height: 6),
        OiLabel.small(
          l10n.workflowsDeviceSummary(vm.summaryOf(run.workflow)),
          color: muted,
        ),
        const SizedBox(height: 20),
        WorkflowProgressCard(
          headline: run.headline(l10n),
          clock: DurationFormatter.clock(run.elapsed),
          progress: run.progress,
        ),
        const SizedBox(height: 20),
        for (final entry in vm.timeline.value)
          WorkflowTimelineRow(
            entry: entry,
            title: entry.step.title(l10n),
            subtitle: entry.subtitle(l10n),
            tag: entry.state.tag(l10n),
          ),
      ],
    );
  }
}
