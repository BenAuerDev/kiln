import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../domain/models/workflow_timeline_entry.dart';

/// The numbered circle of a timeline row: ✓ when done, accent when active.
class WorkflowStepDot extends StatelessWidget {
  const WorkflowStepDot({required this.number, required this.state, super.key});

  final int number;
  final WorkflowStepState state;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final (background, foreground, border) = switch (state) {
      WorkflowStepState.done => (
        kiln.surfaces.text,
        kiln.surfaces.background,
        kiln.surfaces.text,
      ),
      WorkflowStepState.active => (
        kiln.accent.accent,
        kiln.accent.onAccent,
        kiln.accent.accent,
      ),
      WorkflowStepState.upcoming => (
        kiln.surfaces.surface,
        kiln.surfaces.muted,
        kiln.surfaces.border,
      ),
    };
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: border),
      ),
      child: state == WorkflowStepState.done
          ? Icon(OiIcons.check, size: 14, color: foreground)
          : OiLabel.tiny('$number', color: foreground),
    );
  }
}
