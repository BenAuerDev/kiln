import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/theme/build_context_x.dart';

/// Circular outlined icon button from the control mockup (header, −/+).
class VolcanoRoundButton extends StatelessWidget {
  const VolcanoRoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.size = 56,
    this.iconSize = 22,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.kiln.surfaces;
    final radius = BorderRadius.circular(size / 2);
    return OiTappable(
      semanticLabel: semanticLabel,
      enabled: enabled,
      onTap: onTap,
      clipBorderRadius: radius,
      child: OiSurface(
        color: surfaces.surface,
        borderRadius: radius,
        border: OiBorderStyle.solid(surfaces.border, 1, borderRadius: radius),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: OiIcon.decorative(
              icon: icon,
              size: iconSize,
              color: surfaces.text,
            ),
          ),
        ),
      ),
    );
  }
}
