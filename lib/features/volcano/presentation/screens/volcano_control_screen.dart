import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../view_models/volcano_control_view_model.dart';
import '../view_models/volcano_tab.dart';
import '../widgets/volcano_bottom_bar.dart';
import '../widgets/volcano_gauge_section.dart';
import '../widgets/volcano_header.dart';
import '../widgets/volcano_preset_row.dart';
import '../widgets/volcano_target_control.dart';
import '../widgets/volcano_toggle_row.dart';

class VolcanoControlScreen extends HookWidget {
  const VolcanoControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<VolcanoControlViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return ColoredBox(
      color: context.kiln.surfaces.background,
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: OiPage(
                  breakpoint: OiBreakpoint.compact,
                  children: [
                    VolcanoHeader(vm: vm),
                    const SizedBox(height: 20),
                    VolcanoGaugeSection(vm: vm),
                    const SizedBox(height: 4),
                    VolcanoTargetControl(vm: vm),
                    const SizedBox(height: 20),
                    VolcanoPresetRow(vm: vm),
                    const SizedBox(height: 16),
                    VolcanoToggleRow(vm: vm),
                  ],
                ),
              ),
            ),
          ),
          VolcanoBottomBar(current: VolcanoTab.control, onSelect: vm.selectTab),
        ],
      ),
    );
  }
}
