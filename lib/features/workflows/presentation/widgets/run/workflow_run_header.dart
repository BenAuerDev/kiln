import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';

/// Back, "Workflow" and edit, as in `Workflow.dc.html`.
class WorkflowRunHeader extends StatelessWidget {
  const WorkflowRunHeader({
    required this.onBack,
    required this.onEdit,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;

  /// Obers enforces a 48 dp minimum touch target on touch devices.
  static const _side = 48.0;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox.square(
            dimension: _side,
            child: OiIconButton(
              icon: OiIcons.chevronLeft,
              semanticLabel: l10n.workflowsBack,
              variant: OiButtonVariant.outline,
              onTap: onBack,
            ),
          ),
          Semantics(header: true, child: OiLabel.h4(l10n.workflowsRunTitle)),
          SizedBox.square(
            dimension: _side,
            child: OiIconButton(
              icon: OiIcons.pencil,
              semanticLabel: l10n.workflowsEdit,
              variant: OiButtonVariant.outline,
              onTap: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}
