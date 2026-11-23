import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import 'portable_scale_marker.dart';

/// 40–210° scale with the base → superboost range and three markers.
/// Positions are 0–1 along the scale.
class PortableScaleBar extends StatelessWidget {
  const PortableScaleBar({
    required this.basePosition,
    required this.boostPosition,
    required this.superBoostPosition,
    required this.minLabel,
    required this.maxLabel,
    required this.semanticLabel,
    super.key,
  });

  /// `cubic-bezier(.2,.9,.3,1.2)` from the mockup: a short overshoot.
  static const curve = Cubic(0.2, 0.9, 0.3, 1.2);
  static const duration = Duration(milliseconds: 350);

  final double basePosition;
  final double boostPosition;
  final double superBoostPosition;
  final String minLabel;
  final String maxLabel;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : PortableScaleBar.duration;
    const half = PortableScaleMarker.size / 2;
    final positions = [basePosition, boostPosition, superBoostPosition];
    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: 40,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 17,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: kiln.surfaces.track,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: duration,
                          curve: curve,
                          left: width * basePosition,
                          width:
                              width *
                              (superBoostPosition - basePosition).clamp(0, 1),
                          top: 17,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: kiln.accent.gradient,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: kiln.accent.glow,
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (final (index, position) in positions.indexed)
                          AnimatedPositioned(
                            duration: duration,
                            curve: curve,
                            left: width * position - half,
                            top: 8,
                            child: PortableScaleMarker(
                              number: index + 1,
                              filled: index == 0,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OiLabel.tiny(minLabel, color: kiln.surfaces.muted),
                  OiLabel.tiny(maxLabel, color: kiln.surfaces.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
