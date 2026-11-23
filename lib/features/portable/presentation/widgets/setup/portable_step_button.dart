import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// 44×44 rounded −/+ button of a ladder row.
class PortableStepButton extends StatelessWidget {
  const PortableStepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.kiln.surfaces;
    final radius = BorderRadius.circular(14);
    return OiTappable(
      semanticLabel: semanticLabel,
      enabled: enabled,
      onTap: onTap,
      clipBorderRadius: radius,
      child: SizedBox.square(
        dimension: 44,
        child: OiSurface(
          color: surfaces.surfaceRaised,
          borderRadius: radius,
          border: OiBorderStyle.solid(surfaces.border, 1, borderRadius: radius),
          child: Center(
            child: OiIcon.decorative(
              icon: icon,
              size: 18,
              color: surfaces.text,
            ),
          ),
        ),
      ),
    );
  }
}
