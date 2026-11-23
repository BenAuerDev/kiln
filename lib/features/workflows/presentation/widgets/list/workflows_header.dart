import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../../devices/presentation/widgets/demo/demo_badge.dart';

/// "Workflows" and a line on what they do.
class WorkflowsHeader extends StatelessWidget {
  const WorkflowsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: OiLabel.h2(l10n.workflowsTitle),
              ),
            ),
            const DemoBadge(),
          ],
        ),
        OiLabel.small(l10n.workflowsIntro, color: context.kiln.surfaces.muted),
      ],
    );
  }
}
