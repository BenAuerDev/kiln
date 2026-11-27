import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../../../portable/presentation/widgets/common/portable_card.dart';
import '../view_models/ramp_view_model.dart';
import 'ramp_choice_grid.dart';

/// Choose and run a ramp (Setup tab): the presets and the user's own ramps
/// in one grid with "+ New", and "Edit" for a chosen user ramp. Self-contained (ARCHITECTURE.md,
/// screens and widgets): its state lives in repository signals.
class PortableRampCard extends HookWidget {
  const PortableRampCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<RampViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return SignalBuilder(
      builder: (context) {
        final l10n = getAppLocalizations(context);
        final kiln = context.kiln;
        final running = vm.activeRun.value != null;
        final line = vm.statusLine.value;
        final selected = vm.selected.value;
        return PortableCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Semantics(
                    header: true,
                    child: OiLabel.bodyStrong(l10n.rampsTitle),
                  ),
                  OiLabel.small(l10n.rampsIntro, color: kiln.surfaces.muted),
                ],
              ),
              RampChoiceGrid(
                options: [
                  for (final profile in vm.options.value)
                    (name: vm.nameOf(profile), range: vm.rangeOf(profile)),
                ],
                checkedIndex: vm.selectedIndex.value,
                onSelect: vm.select,
                onNew: vm.newRamp,
                semanticLabel: l10n.rampsChoose,
                newLabel: l10n.rampsNewShort,
                newSemanticLabel: l10n.rampsNew,
                enabled: !running,
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: OiLabel.small(
                      vm.selectedSummary.value,
                      color: kiln.surfaces.muted,
                    ),
                  ),
                  if (!selected.isPreset && !running)
                    OiButton.ghost(
                      label: l10n.rampsEdit,
                      icon: OiIcons.pencil,
                      semanticLabel: l10n.rampsEditSemantics(
                        vm.nameOf(selected),
                      ),
                      onTap: () => vm.edit(selected.id),
                    ),
                ],
              ),
              if (line.isNotEmpty)
                OiLabel.smallStrong(line, color: kiln.accent.accentText),
              if (running)
                OiButton.outline(
                  label: l10n.rampsStop,
                  fullWidth: true,
                  onTap: vm.stop,
                )
              else
                OiButton.primary(
                  label: vm.boosting.value
                      ? l10n.rampsNotWhileBoosting
                      : l10n.rampsStart,
                  icon: OiIcons.trendingUp,
                  fullWidth: true,
                  enabled: vm.canStart.value,
                  onTap: vm.start,
                ),
            ],
          ),
        );
      },
    );
  }
}
