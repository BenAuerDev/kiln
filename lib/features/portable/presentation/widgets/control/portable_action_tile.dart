import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

/// Large Heater / Boost button from the control mockup.
class PortableActionTile extends StatelessWidget {
  const PortableActionTile({
    required this.icon,
    required this.label,
    required this.on,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.semanticLabel,
    this.borderColor,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? semanticLabel;
  final bool on;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final border = borderColor;
    return OiTappable(
      role: OiTappableRole.toggle,
      toggled: on,
      semanticLabel: semanticLabel ?? label,
      enabled: enabled,
      onTap: onTap,
      clipBorderRadius: radius,
      child: SizedBox(
        height: 72,
        child: OiSurface(
          color: background,
          borderRadius: radius,
          border: border == null
              ? null
              : OiBorderStyle.solid(border, 1, borderRadius: radius),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              OiIcon.decorative(icon: icon, size: 22, color: foreground),
              Flexible(
                child: OiLabel.bodyStrong(
                  label,
                  color: foreground,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
