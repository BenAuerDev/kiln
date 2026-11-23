import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// Numbered ring on the ladder scale. The base marker is filled.
class PortableScaleMarker extends StatelessWidget {
  const PortableScaleMarker({
    required this.number,
    required this.filled,
    super.key,
  });

  static const size = 24.0;

  final int number;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? kiln.accent.accent : kiln.surfaces.background,
          border: Border.all(color: kiln.accent.accent, width: 3),
        ),
        child: Center(
          child: OiLabel.overline(
            '$number',
            color: filled ? kiln.accent.onAccent : kiln.accent.accentText,
          ),
        ),
      ),
    );
  }
}
