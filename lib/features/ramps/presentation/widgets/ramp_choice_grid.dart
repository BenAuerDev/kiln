import 'package:flutter/widgets.dart';

import '../../../portable/presentation/widgets/common/portable_card.dart';
import '../../../portable/presentation/widgets/setup/portable_quick_setup_control.dart';
import '../../../portable/presentation/widgets/setup/portable_quick_setup_option.dart';
import 'ramp_new_tile.dart';

/// The ramp selector: presets and the user's own ramps as radio tiles,
/// three per row in one box like the quick setups, then a "+ New" tile.
class RampChoiceGrid extends StatelessWidget {
  const RampChoiceGrid({
    required this.options,
    required this.checkedIndex,
    required this.onSelect,
    required this.onNew,
    required this.semanticLabel,
    required this.newLabel,
    required this.newSemanticLabel,
    this.enabled = true,
    super.key,
  });

  static const columns = 3;

  final List<PortableQuickSetupChoice> options;
  final int? checkedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onNew;
  final String semanticLabel;

  /// "New" on the tile; [newSemanticLabel] "New ramp" for screen readers.
  final String newLabel;
  final String newSemanticLabel;

  /// Choosing is off while a ramp runs; "New" stays possible.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final (index, option) in options.indexed)
        PortableQuickSetupOption(
          name: option.name,
          range: option.range,
          checked: index == checkedIndex,
          enabled: enabled,
          onTap: () => onSelect(index),
        ),
      RampNewTile(
        label: newLabel,
        semanticLabel: newSemanticLabel,
        onTap: onNew,
      ),
    ];
    // One container around every row, so all tiles form one radio group.
    return Semantics(
      label: semanticLabel,
      container: true,
      child: PortableCard(
        radius: 16,
        padding: const EdgeInsets.all(4),
        child: Column(
          spacing: 4,
          children: [
            for (var start = 0; start < tiles.length; start += columns)
              Row(
                spacing: 4,
                children: [
                  for (var i = start; i < start + columns; i++)
                    Expanded(
                      child: i < tiles.length
                          ? tiles[i]
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
