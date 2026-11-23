import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 270° gauge: track, gradient progress arc with glow, and a target dot.
class KilnGaugePainter extends CustomPainter {
  const KilnGaugePainter({
    required this.progress,
    required this.target,
    required this.trackColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.glowColor,
    required this.glowOpacity,
    required this.dotFill,
    required this.dotStroke,
  });

  /// Both 0–1 along the arc.
  final double progress;
  final double target;
  final Color trackColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color glowColor;
  final double glowOpacity;
  final Color dotFill;
  final Color dotStroke;

  static const _start = 135 * math.pi / 180;
  static const _sweep = 270 * math.pi / 180;
  static const _strokeWidth = 16.0;
  static const _dotRadius = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _dotRadius - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _start, _sweep, false, stroke..color = trackColor);

    if (progress > 0) {
      final sweep = _sweep * progress;
      canvas.drawArc(
        rect,
        _start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = glowColor.withValues(alpha: glowColor.a * glowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawArc(
        rect,
        _start,
        sweep,
        false,
        stroke
          ..color = gradientEnd
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [gradientStart, gradientEnd],
          ).createShader(rect),
      );
    }

    final angle = _start + _sweep * target;
    final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas
      ..drawCircle(dot, _dotRadius, Paint()..color = dotFill)
      ..drawCircle(
        dot,
        _dotRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = dotStroke,
      );
  }

  @override
  bool shouldRepaint(KilnGaugePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      target != oldDelegate.target ||
      trackColor != oldDelegate.trackColor ||
      gradientStart != oldDelegate.gradientStart ||
      gradientEnd != oldDelegate.gradientEnd ||
      glowColor != oldDelegate.glowColor ||
      glowOpacity != oldDelegate.glowOpacity ||
      dotFill != oldDelegate.dotFill ||
      dotStroke != oldDelegate.dotStroke;
}
