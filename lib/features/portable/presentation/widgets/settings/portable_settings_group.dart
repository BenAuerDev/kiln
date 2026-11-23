import 'package:flutter/widgets.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../common/portable_card.dart';
import '../common/portable_section_label.dart';

/// Section label over a card whose rows are separated by hairlines.
class PortableSettingsGroup extends StatelessWidget {
  const PortableSettingsGroup({
    required this.label,
    required this.children,
    super.key,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final border = context.kiln.surfaces.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        PortableSectionLabel(label),
        PortableCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: index == 0
                        ? null
                        : Border(top: BorderSide(color: border)),
                  ),
                  child: child,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
