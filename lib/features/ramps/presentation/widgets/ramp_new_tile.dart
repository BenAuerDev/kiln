import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/theme/build_context_x.dart';

/// "+ New" in the ramp grid: as tall as a ramp tile, in the accent text
/// colour; [semanticLabel] says what it makes ("New ramp").
class RampNewTile extends StatelessWidget {
  const RampNewTile({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.kiln.accent.accentText;
    return OiTappable(
      semanticLabel: semanticLabel,
      onTap: onTap,
      clipBorderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            OiIcon.decorative(icon: OiIcons.plus, size: 16, color: color),
            OiLabel.smallStrong(label, color: color, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
