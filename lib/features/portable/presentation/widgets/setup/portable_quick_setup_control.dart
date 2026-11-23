import 'package:flutter/widgets.dart';

import '../common/portable_card.dart';
import 'portable_quick_setup_option.dart';

/// One option of [PortableQuickSetupControl].
typedef PortableQuickSetupChoice = ({String name, String range});

/// Segmented radio group of quick setups. No option is checked when the
/// device matches none of them.
class PortableQuickSetupControl extends StatelessWidget {
  const PortableQuickSetupControl({
    required this.options,
    required this.checkedIndex,
    required this.onSelect,
    required this.semanticLabel,
    this.enabled = true,
    super.key,
  });

  final List<PortableQuickSetupChoice> options;
  final int? checkedIndex;
  final ValueChanged<int> onSelect;
  final String semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    container: true,
    child: PortableCard(
      radius: 16,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (index, option) in options.indexed)
            Expanded(
              child: PortableQuickSetupOption(
                name: option.name,
                range: option.range,
                checked: index == checkedIndex,
                enabled: enabled,
                onTap: () => onSelect(index),
              ),
            ),
        ],
      ),
    ),
  );
}
