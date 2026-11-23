import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../view_models/workflow_run_banner_view_model.dart';

/// "Running now" with the current step while a workflow runs, so it is
/// never forgotten; Open returns to it. Self-contained (ARCHITECTURE.md,
/// screens and widgets): placed on the Control and Workflows tabs, it owns
/// its view model.
class WorkflowRunBanner extends HookWidget {
  const WorkflowRunBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<WorkflowRunBannerViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return SignalBuilder(
      builder: (context) {
        if (vm.activeRun.value == null) return const SizedBox.shrink();
        final l10n = getAppLocalizations(context);
        final kiln = context.kiln;
        return OiSurface(
          color: kiln.surfaces.surfaceRaised,
          border: OiBorderStyle.solid(kiln.accent.accent, 1),
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    OiLabel.overline(
                      l10n.workflowsRunningNow.toUpperCase(),
                      semanticsLabel: l10n.workflowsRunningNow,
                      color: kiln.accent.accentText,
                    ),
                    OiLabel.bodyStrong(
                      vm.name.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    OiLabel.small(
                      vm.headline.value,
                      color: kiln.surfaces.muted,
                    ),
                  ],
                ),
              ),
              OiButton.outline(label: l10n.workflowsOpenRun, onTap: vm.open),
            ],
          ),
        );
      },
    );
  }
}
