import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';

/// One editable step: title, −/+ and up / down / remove.
class WorkflowStepEditorRow extends StatelessWidget {
  const WorkflowStepEditorRow({
    required this.number,
    required this.title,
    required this.icon,
    required this.onLower,
    required this.onRaise,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  final int number;
  final String title;
  final IconData icon;
  final VoidCallback onLower;
  final VoidCallback onRaise;
  final VoidCallback onRemove;

  /// `null` for the first step.
  final VoidCallback? onMoveUp;

  /// `null` for the last step.
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final surfaces = context.kiln.surfaces;
    return OiSurface(
      color: surfaces.surface,
      border: OiBorderStyle.solid(surfaces.border, 1),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 10,
            children: [
              OiLabel.smallStrong('$number', color: surfaces.muted),
              Icon(icon, size: 18, color: surfaces.text),
              Expanded(child: OiLabel.bodyStrong(title)),
              OiIconButton(
                icon: OiIcons.trash2,
                semanticLabel: l10n.workflowsEditorRemove(title),
                variant: OiButtonVariant.ghost,
                onTap: onRemove,
              ),
            ],
          ),
          Row(
            children: [
              OiIconButton(
                icon: OiIcons.minus,
                semanticLabel: l10n.workflowsEditorLower(title),
                variant: OiButtonVariant.ghost,
                onTap: onLower,
              ),
              OiIconButton(
                icon: OiIcons.plus,
                semanticLabel: l10n.workflowsEditorRaise(title),
                variant: OiButtonVariant.ghost,
                onTap: onRaise,
              ),
              const Spacer(),
              OiIconButton(
                icon: OiIcons.chevronUp,
                semanticLabel: l10n.workflowsEditorMoveUp(title),
                variant: OiButtonVariant.ghost,
                enabled: onMoveUp != null,
                onTap: onMoveUp,
              ),
              OiIconButton(
                icon: OiIcons.chevronDown,
                semanticLabel: l10n.workflowsEditorMoveDown(title),
                variant: OiButtonVariant.ghost,
                enabled: onMoveDown != null,
                onTap: onMoveDown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
