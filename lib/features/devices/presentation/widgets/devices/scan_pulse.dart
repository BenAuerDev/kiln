import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../common/radar_rings_painter.dart';

/// Small pulsing dot next to the nearby heading. Still with reduced motion.
class ScanPulse extends HookWidget {
  const ScanPulse({required this.active, super.key});

  final bool active;

  static const _size = 28.0;

  @override
  Widget build(BuildContext context) {
    final animate = active && !MediaQuery.disableAnimationsOf(context);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1800),
    );
    useEffect(() {
      if (animate) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [animate]);
    final progress = useAnimation(controller);
    final color = context.kiln.accent.accentText;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              CustomPaint(
                size: const Size.square(_size),
                painter: RadarRingsPainter(
                  progress: animate ? progress : 0.3,
                  color: color,
                  rings: 2,
                  minScale: 0.4,
                  maxScale: 1.6,
                ),
              ),
            OiSurface(
              color: active ? color : context.colors.textSubtle,
              borderRadius: BorderRadius.circular(4),
              child: const SizedBox.square(dimension: 8),
            ),
          ],
        ),
      ),
    );
  }
}
