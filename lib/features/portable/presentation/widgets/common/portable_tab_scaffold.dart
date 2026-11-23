import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../view_models/portable_tab.dart';
import 'portable_bottom_bar.dart';

/// Scrolling page above the portable bottom bar.
class PortableTabScaffold extends StatelessWidget {
  const PortableTabScaffold({
    required this.tab,
    required this.onSelectTab,
    required this.children,
    super.key,
  });

  final PortableTab tab;
  final ValueChanged<PortableTab> onSelectTab;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ColoredBox(
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
                children: children,
              ),
            ),
          ),
        ),
        PortableBottomBar(current: tab, onSelect: onSelectTab),
      ],
    ),
  );
}
