import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../../../core/theme/kiln_tokens.dart';

/// Status dot plus one muted line, e.g. "Connected", and an optional
/// [trailing] widget after it, e.g. the battery.
class PortableStatusLine extends StatelessWidget {
  const PortableStatusLine({
    required this.text,
    required this.active,
    this.trailing,
    super.key,
  });

  final String text;

  /// Accent dot when `true`, muted dot otherwise.
  final bool active;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return DefaultTextHeightBehavior(
      textHeightBehavior: centredText,
      child: _row(kiln),
    );
  }

  /// Splits a line's extra height evenly above and below the text, so the
  /// letters sit in the middle of their box and line up with the dot and
  /// icons centred next to them (the default puts them ~1.5 px low).
  static const centredText = TextHeightBehavior(
    leadingDistribution: TextLeadingDistribution.even,
  );

  Widget _row(KilnTokens kiln) {
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
        if (trailing case final trailing?)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: trailing,
          ),
      ],
    );
  }
}
