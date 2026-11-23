import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';

/// "Match my device" option with a colour wheel of the finishes.
class PortableMatchDeviceTile extends StatelessWidget {
  const PortableMatchDeviceTile({
    required this.title,
    required this.subtitle,
    required this.wheelColors,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;

  /// Equal slices of the wheel, clockwise from the top.
  final List<Color> wheelColors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final radius = BorderRadius.circular(18);
    final slices = wheelColors.length;
    return OiTappable(
      semanticLabel: getAppLocalizations(
        context,
      ).commonSemanticsTitleSubtitle(title, subtitle),
      selected: selected,
      onTap: onTap,
      clipBorderRadius: radius,
      child: OiSurface(
        color: kiln.surfaces.surface,
        borderRadius: radius,
        border: OiBorderStyle.solid(
          selected ? kiln.accent.accent : kiln.surfaces.border,
          2,
          borderRadius: radius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 14,
          children: [
            SizedBox.square(
              dimension: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    startAngle: 0,
                    endAngle: 2 * math.pi,
                    transform: const GradientRotation(-math.pi / 2),
                    colors: [
                      for (final color in wheelColors) ...[color, color],
                    ],
                    stops: [
                      for (var i = 0; i < slices; i++) ...[
                        i / slices,
                        (i + 1) / slices,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  OiLabel.bodyStrong(title),
                  OiLabel.small(subtitle, color: kiln.surfaces.muted),
                ],
              ),
            ),
            if (selected)
              OiIcon.decorative(
                icon: OiIcons.check,
                size: 20,
                color: kiln.accent.accentText,
              ),
          ],
        ),
      ),
    );
  }
}
