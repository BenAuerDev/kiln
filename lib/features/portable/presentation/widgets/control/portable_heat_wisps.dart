import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../../core/theme/build_context_x.dart';
import 'portable_heat_wisps_painter.dart';

/// Rising heat wisps while the heater warms up. Paints nothing under reduced
/// motion.
class PortableHeatWisps extends HookWidget {
  const PortableHeatWisps({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 2400),
    );
    useEffect(() {
      if (reduceMotion) {
        controller.stop();
      } else {
        controller.repeat();
      }
      return null;
    }, [reduceMotion]);
    final progress = useAnimation(controller);
    if (reduceMotion) return SizedBox.square(dimension: size);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: PortableHeatWispsPainter(
            progress: progress,
            color: context.kiln.accent.glow,
          ),
        ),
      ),
    );
  }
}
