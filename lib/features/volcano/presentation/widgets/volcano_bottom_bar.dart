import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/l10n/get_app_localizations.dart';
import '../view_models/volcano_tab.dart';

/// Control / Workflows / Devices. Insights joins once it exists.
class VolcanoBottomBar extends StatelessWidget {
  const VolcanoBottomBar({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final VolcanoTab current;
  final ValueChanged<VolcanoTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return OiBottomBar(
      currentIndex: VolcanoTab.values.indexOf(current),
      onTap: (index) => onSelect(VolcanoTab.values[index]),
      items: [
        for (final tab in VolcanoTab.values)
          switch (tab) {
            VolcanoTab.control => OiNavigationItem(
              icon: OiIcons.gauge,
              label: l10n.navControl,
            ),
            VolcanoTab.workflows => OiNavigationItem(
              icon: OiIcons.listOrdered,
              label: l10n.navWorkflows,
            ),
            VolcanoTab.devices => OiNavigationItem(
              icon: OiIcons.bluetooth,
              label: l10n.navDevices,
            ),
          },
      ],
    );
  }
}
