import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/service_locator.dart';
import '../view_models/portable_setup_view_model.dart';
import '../view_models/portable_tab.dart';
import '../widgets/common/portable_tab_scaffold.dart';
import '../widgets/setup/portable_ladder_card.dart';
import '../widgets/setup/portable_quick_setup_section.dart';
import '../widgets/setup/portable_setup_header.dart';

/// "Set it once, then use the button" (`design/Veazy.dc.html`).
class PortableSetupScreen extends HookWidget {
  const PortableSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<PortableSetupViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return PortableTabScaffold(
      tab: PortableTab.setup,
      onSelectTab: vm.selectTab,
      children: [
        PortableSetupHeader(vm: vm),
        const SizedBox(height: 18),
        PortableLadderCard(vm: vm),
        const SizedBox(height: 20),
        PortableQuickSetupSection(vm: vm),
      ],
    );
  }
}
