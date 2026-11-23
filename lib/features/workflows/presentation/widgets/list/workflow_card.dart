import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';

/// A workflow in the list: name, steps and duration, edit and Start.
class WorkflowCard extends StatelessWidget {
  const WorkflowCard({
    required this.name,
    required this.summary,
    required this.starting,
    required this.canStart,
    required this.onStart,
    required this.onEdit,
    super.key,
  });

  final String name;
  final String summary;
  final bool starting;
  final bool canStart;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final surfaces = context.kiln.surfaces;
    return OiSurface(
      color: surfaces.surface,
      border: OiBorderStyle.solid(surfaces.border, 1),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                OiLabel.bodyStrong(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                OiLabel.small(summary, color: surfaces.muted),
              ],
            ),
          ),
          OiIconButton(
            icon: OiIcons.pencil,
            semanticLabel: l10n.workflowsEditSemantics(name),
            variant: OiButtonVariant.ghost,
            onTap: onEdit,
          ),
          OiButton.primary(
            label: l10n.workflowsStart,
            icon: OiIcons.play,
            semanticLabel: l10n.workflowsStartSemantics(name),
            loading: starting,
            enabled: canStart,
            onTap: onStart,
          ),
        ],
      ),
    );
  }
}
