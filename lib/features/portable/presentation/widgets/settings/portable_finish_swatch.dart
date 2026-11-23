import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../../../core/theme/kiln_tokens.dart';

/// Round gradient swatch with its name; ringed in its accent when selected.
class PortableFinishSwatch extends StatelessWidget {
  const PortableFinishSwatch({
    required this.label,
    required this.semanticLabel,
    required this.tokens,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String semanticLabel;

  /// Tokens of the finish shown, not of the active theme.
  final KilnAccentTokens tokens;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.kiln.surfaces;
    return OiTappable(
      semanticLabel: semanticLabel,
      selected: selected,
      onTap: onTap,
      child: Column(
        spacing: 8,
        children: [
          SizedBox.square(
            dimension: 62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.accent.withValues(alpha: selected ? 1 : 0),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tokens.gradientStart, tokens.gradientEnd],
                    ),
                  ),
                ),
              ),
            ),
          ),
          OiLabel.tiny(
            label,
            color: selected ? surfaces.text : surfaces.muted,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
