import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../view_models/ramp_view_model.dart';

/// "Ramp running" with the next step on the Control tab, so a running ramp
/// is never forgotten. Self-contained like [PortableRampCard]'s view model.
class PortableRampBanner extends HookWidget {
  const PortableRampBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<RampViewModel>());
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
                      l10n.rampsRunning.toUpperCase(),
                      semanticsLabel: l10n.rampsRunning,
                      color: kiln.accent.accentText,
                    ),
                    OiLabel.small(
                      vm.statusLine.value,
                      color: kiln.surfaces.text,
                    ),
                  ],
                ),
              ),
              OiButton.outline(label: l10n.rampsStop, onTap: vm.stop),
            ],
          ),
        );
      },
    );
  }
}
