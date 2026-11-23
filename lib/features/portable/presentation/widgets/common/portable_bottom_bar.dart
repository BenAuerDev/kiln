import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/portable_tab.dart';

/// Control / Setup / Devices.
class PortableBottomBar extends StatelessWidget {
  const PortableBottomBar({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final PortableTab current;
  final ValueChanged<PortableTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return OiBottomBar(
      currentIndex: PortableTab.values.indexOf(current),
      onTap: (index) => onSelect(PortableTab.values[index]),
      items: [
        for (final tab in PortableTab.values)
          switch (tab) {
            PortableTab.control => OiNavigationItem(
              icon: OiIcons.gauge,
              label: l10n.navControl,
            ),
            PortableTab.setup => OiNavigationItem(
              icon: OiIcons.slidersVertical,
              label: l10n.navSetup,
            ),
            PortableTab.devices => OiNavigationItem(
              icon: OiIcons.bluetooth,
              label: l10n.navDevices,
            ),
          },
      ],
    );
  }
}
