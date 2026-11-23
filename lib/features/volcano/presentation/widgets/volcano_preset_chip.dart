import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/theme/build_context_x.dart';

class VolcanoPresetChip extends StatelessWidget {
  const VolcanoPresetChip({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final radius = BorderRadius.circular(22);
    final background = selected ? kiln.accent.accent : kiln.surfaces.surface;
    final border = selected ? kiln.accent.accent : kiln.surfaces.border;
    return OiTappable(
      semanticLabel: semanticLabel,
      selected: selected,
      enabled: enabled,
      onTap: onTap,
      clipBorderRadius: radius,
      child: OiSurface(
        color: background,
        borderRadius: radius,
        border: OiBorderStyle.solid(border, 1, borderRadius: radius),
        child: SizedBox(
          height: 44,
          child: Center(
            child: OiLabel.bodyStrong(
              label,
              color: selected ? kiln.accent.onAccent : kiln.surfaces.text,
            ),
          ),
        ),
      ),
    );
  }
}
