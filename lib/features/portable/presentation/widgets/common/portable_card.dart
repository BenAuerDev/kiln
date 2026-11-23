import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// Bordered surface card used for grouped content.
class PortableCard extends StatelessWidget {
  const PortableCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 20,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.kiln.surfaces;
    final borderRadius = BorderRadius.circular(radius);
    return OiSurface(
      color: surfaces.surface,
      borderRadius: borderRadius,
      border: OiBorderStyle.solid(
        surfaces.border,
        1,
        borderRadius: borderRadius,
      ),
      padding: padding,
      child: child,
    );
  }
}
