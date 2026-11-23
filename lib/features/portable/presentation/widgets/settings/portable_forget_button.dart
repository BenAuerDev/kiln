import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// Outlined destructive "Forget this device" button.
class PortableForgetButton extends StatelessWidget {
  const PortableForgetButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return OiTappable(
      semanticLabel: label,
      enabled: enabled,
      onTap: onTap,
      clipBorderRadius: radius,
      child: SizedBox(
        height: 52,
        child: OiSurface(
          borderRadius: radius,
          border: OiBorderStyle.solid(
            context.kiln.surfaces.border,
            1,
            borderRadius: radius,
          ),
          child: Center(
            child: OiLabel.bodyStrong(label, color: context.colors.error.base),
          ),
        ),
      ),
    );
  }
}
