import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../domain/models/workflow_timeline_entry.dart';
import 'workflow_step_dot.dart';

/// One step of the timeline: dot and connector, title, subtitle and tag.
class WorkflowTimelineRow extends StatelessWidget {
  const WorkflowTimelineRow({
    required this.entry,
    required this.title,
    required this.subtitle,
    required this.tag,
    super.key,
  });

  final WorkflowTimelineEntry entry;
  final String title;
  final String subtitle;

  /// "Done", "Now" or empty.
  final String tag;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final upcoming = entry.state == WorkflowStepState.upcoming;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                WorkflowStepDot(number: entry.number, state: entry.state),
                Expanded(
                  child: Container(
                    width: 2,
                    constraints: const BoxConstraints(minHeight: 18),
                    color: entry.isLast
                        ? null
                        : entry.state == WorkflowStepState.done
                        ? kiln.surfaces.text
                        : kiln.surfaces.border,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        OiLabel.bodyStrong(
                          title,
                          color: upcoming ? kiln.surfaces.muted : null,
                        ),
                        OiLabel.small(subtitle, color: kiln.surfaces.muted),
                      ],
                    ),
                  ),
                  if (tag.isNotEmpty)
                    OiLabel.smallStrong(
                      tag,
                      color: entry.state == WorkflowStepState.active
                          ? kiln.accent.accentText
                          : kiln.surfaces.muted,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
