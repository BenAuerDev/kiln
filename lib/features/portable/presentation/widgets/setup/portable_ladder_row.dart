import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import 'portable_step_button.dart';

/// One step of the ladder: icon, name and hint, value with sub line, −/+.
class PortableLadderRow extends StatelessWidget {
  const PortableLadderRow({
    required this.icon,
    required this.name,
    required this.hint,
    required this.value,
    required this.sub,
    required this.lowerLabel,
    required this.raiseLabel,
    required this.onLower,
    required this.onRaise,
    this.subAccent = false,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String name;
  final String hint;
  final String value;
  final String sub;

  /// Sub line in accent text colour (boost targets) instead of muted.
  final bool subAccent;
  final String lowerLabel;
  final String raiseLabel;
  final VoidCallback onLower;
  final VoidCallback onRaise;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: kiln.surfaces.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            SizedBox.square(
              dimension: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kiln.surfaces.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: OiIcon.decorative(
                    icon: icon,
                    size: 20,
                    color: kiln.accent.accentText,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: OiLabel.bodyStrong(name, maxLines: 1),
                  ),
                  OiLabel.tiny(
                    hint,
                    color: kiln.surfaces.muted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OiLabel.h3(value),
                  OiLabel.tiny(
                    sub,
                    color: subAccent
                        ? kiln.accent.accentText
                        : kiln.surfaces.muted,
                  ),
                ],
              ),
            ),
            Row(
              spacing: 6,
              children: [
                PortableStepButton(
                  icon: OiIcons.minus,
                  semanticLabel: lowerLabel,
                  onTap: onLower,
                  enabled: enabled,
                ),
                PortableStepButton(
                  icon: OiIcons.plus,
                  semanticLabel: raiseLabel,
                  onTap: onRaise,
                  enabled: enabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
