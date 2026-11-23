import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/service_locator.dart';
import '../../../ramps/presentation/widgets/portable_ramp_banner.dart';
import '../view_models/portable_control_view_model.dart';
import '../view_models/portable_tab.dart';
import '../widgets/common/portable_tab_scaffold.dart';
import '../widgets/control/portable_action_row.dart';
import '../widgets/control/portable_control_header.dart';
import '../widgets/control/portable_gauge_section.dart';
import '../widgets/control/portable_preset_row.dart';
import '../widgets/control/portable_target_control.dart';

/// Live control (`design/Main.dc.html`, device = veazy).
class PortableControlScreen extends HookWidget {
  const PortableControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<PortableControlViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return PortableTabScaffold(
      tab: PortableTab.control,
      onSelectTab: vm.selectTab,
      children: [
        PortableControlHeader(vm: vm),
        const SizedBox(height: 16),
        const PortableRampBanner(),
        const SizedBox(height: 4),
        PortableGaugeSection(vm: vm),
        const SizedBox(height: 4),
        PortableTargetControl(vm: vm),
        const SizedBox(height: 20),
        PortablePresetRow(vm: vm),
        const SizedBox(height: 16),
        PortableActionRow(vm: vm),
      ],
    );
  }
}
