import 'package:flutter/widgets.dart';

/// Three rising, fading glow wisps above the gauge centre
/// (`kilnRise` in `design/Main.dc.html`), laid out on a 300×300 box.
class PortableHeatWispsPainter extends CustomPainter {
  const PortableHeatWispsPainter({required this.progress, required this.color});

  /// 0–1 through one 2.4 s cycle.
  final double progress;
  final Color color;

  static const _diameter = 22.0;
  static const _rise = 90.0;
  static const _origins = [
    Offset(120, 110),
    Offset(150, 118),
    Offset(136, 104),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 300;
    for (final (index, origin) in _origins.indexed) {
      final t = (progress - index / _origins.length) % 1;
      final opacity = t < 0.2 ? t / 0.2 * 0.8 : 0.8 * (1 - (t - 0.2) / 0.8);
      final grow = 0.6 + 0.8 * t;
      final radius = _diameter / 2 * grow * scale;
      final center =
          (origin + const Offset(_diameter / 2, _diameter / 2)) * scale -
          Offset(0, _rise * Curves.easeOut.transform(t) * scale);
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: color.a * opacity),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.7],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(PortableHeatWispsPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
