import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// Status dot plus one muted line, e.g. "Connected · 72% battery".
class PortableStatusLine extends StatelessWidget {
  const PortableStatusLine({
    required this.text,
    required this.active,
    super.key,
  });

  final String text;

  /// Accent dot when `true`, muted dot otherwise.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return Row(
      spacing: 6,
      children: [
        SizedBox.square(
          dimension: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? kiln.accent.accent : kiln.surfaces.muted,
            ),
          ),
        ),
        Flexible(
          child: OiLabel.small(
            text,
            color: kiln.surfaces.muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
