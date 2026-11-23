import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../../../core/widgets/kiln_gauge_painter.dart';

/// Gauge ring. Pulses its glow while heating and breathes slowly when ready,
/// unless the system asks for reduced motion.
class PortableGauge extends HookWidget {
  const PortableGauge({
    required this.progress,
    required this.targetPosition,
    required this.heating,
    required this.ready,
    required this.semanticLabel,
    this.size = 300,
    super.key,
  });

  /// Both 0–1 along the arc.
  final double progress;
  final double targetPosition;
  final bool heating;
  final bool ready;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animate = !reduceMotion && (heating || ready);
    final pulse = useAnimationController(
      duration: Duration(milliseconds: heating ? 1600 : 3000),
    );
    useEffect(() {
      if (animate) {
        pulse.repeat(reverse: true);
      } else {
        pulse.stop();
      }
      return null;
    }, [animate, heating]);
    final curve = useMemoized(
      () => CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
      [pulse],
    );
    useEffect(() => curve.dispose, [curve]);
    final wave = useAnimation(curve);
    final glowOpacity = heating && animate ? 0.55 + 0.45 * wave : 1.0;
    final scale = ready && animate ? 1 + 0.03 * wave : 1.0;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Transform.scale(
        scale: scale,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: progress),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, _) => CustomPaint(
            size: Size.square(size),
            painter: KilnGaugePainter(
              progress: value,
              target: targetPosition,
              trackColor: kiln.surfaces.track,
              gradientStart: kiln.accent.gradientStart,
              gradientEnd: kiln.accent.gradientEnd,
              glowColor: kiln.accent.glow,
              glowOpacity: glowOpacity,
              dotFill: kiln.surfaces.background,
              dotStroke: kiln.accent.accent,
            ),
          ),
        ),
      ),
    );
  }
}
