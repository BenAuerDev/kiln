import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Expanding rings around the centre. [progress] runs from 0 to 1 per cycle;
/// a fixed progress draws a still frame for reduced motion.
class RadarRingsPainter extends CustomPainter {
  const RadarRingsPainter({
    required this.progress,
    required this.color,
    this.rings = 3,
    this.minScale = 0.35,
    this.maxScale = 1,
    this.strokeWidth = 2,
  });

  final double progress;
  final Color color;
  final int rings;
  final double minScale;
  final double maxScale;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    for (var i = 0; i < rings; i++) {
      final t = (progress + i / rings) % 1;
      final eased = 1 - math.pow(1 - t, 3).toDouble();
      final scale = minScale + (maxScale - minScale) * eased;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color.withValues(alpha: color.a * (1 - t));
      canvas.drawCircle(center, radius * scale - strokeWidth / 2, paint);
    }
  }

  @override
  bool shouldRepaint(RadarRingsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.rings != rings;
}
