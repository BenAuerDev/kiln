import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../common/radar_rings_painter.dart';

/// The welcome radar: a floating Bluetooth tile with rings while scanning.
/// Still with reduced motion.
class RadarScan extends HookWidget {
  const RadarScan({
    required this.scanning,
    required this.semanticLabel,
    super.key,
  });

  final bool scanning;
  final String semanticLabel;

  static const _size = 240.0;
  static const _core = 100.0;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animate = !reduceMotion;
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 2400),
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
    final kiln = context.kiln;
    final float = animate ? -3 - 3 * math.sin(progress * 2 * math.pi) : 0.0;

    return Semantics(
      label: scanning ? semanticLabel : null,
      liveRegion: scanning,
      child: SizedBox.square(
        dimension: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (scanning)
              CustomPaint(
                size: const Size.square(_size),
                painter: RadarRingsPainter(
                  progress: animate ? progress : 0,
                  color: kiln.accent.accentText.withValues(alpha: 0.7),
                ),
              ),
            Transform.translate(
              offset: Offset(0, float),
              child: OiSurface(
                color: context.colors.surface,
                border: OiBorderStyle.solid(context.colors.border, 1),
                borderRadius: BorderRadius.circular(32),
                shadow: [BoxShadow(color: kiln.accent.glow, blurRadius: 48)],
                child: SizedBox.square(
                  dimension: _core,
                  child: Center(
                    child: OiIcon.decorative(
                      icon: OiIcons.bluetooth,
                      size: 44,
                      color: kiln.accent.accentText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
