import 'package:flutter/widgets.dart';

/// A small battery: outlined body with a nub, filled up to [level] (0–1),
/// and a lightning bolt cut into it while [charging]. Drawn on a 24×12 grid.
class PortableBatteryPainter extends CustomPainter {
  const PortableBatteryPainter({
    required this.level,
    required this.charging,
    required this.outline,
    required this.fill,
  });

  final double level;
  final bool charging;
  final Color outline;
  final Color fill;

  static const _stroke = 1.4;
  static const _bodyRight = 21.0;
  static const _gap = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 24, size.height / 12);

    const half = _stroke / 2;
    final body = RRect.fromLTRBR(
      half,
      half,
      _bodyRight - half,
      12 - half,
      const Radius.circular(3.2),
    );
    canvas
      ..drawRRect(
        body,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke,
      )
      ..drawRRect(
        RRect.fromLTRBR(_bodyRight + 0.6, 4, 24, 8, const Radius.circular(1.2)),
        Paint()..color = outline,
      );

    // Inner fill, inset from the outline. A sliver stays visible above 0 %.
    const left = _stroke + _gap;
    const right = _bodyRight - _stroke - _gap;
    const top = _stroke + _gap;
    const bottom = 12 - _stroke - _gap;
    final clamped = level.clamp(0.0, 1.0);
    if (clamped > 0) {
      final width = ((right - left) * clamped).clamp(1.6, right - left);
      canvas.saveLayer(Offset.zero & const Size(24, 12), Paint());
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          top,
          left + width,
          bottom,
          const Radius.circular(1.6),
        ),
        Paint()..color = fill,
      );
      if (charging) {
        // Clear a halo around the bolt so it reads on any fill level.
        canvas.drawPath(
          _bolt,
          Paint()
            ..blendMode = BlendMode.clear
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeJoin = StrokeJoin.round,
        );
      }
      canvas.restore();
    }
    if (charging) canvas.drawPath(_bolt, Paint()..color = outline);
    canvas.restore();
  }

  static final Path _bolt = Path()
    ..moveTo(11.6, 1.6)
    ..lineTo(6.6, 6.8)
    ..lineTo(10, 6.8)
    ..lineTo(9, 10.4)
    ..lineTo(14, 5.2)
    ..lineTo(10.6, 5.2)
    ..close();

  @override
  bool shouldRepaint(PortableBatteryPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.charging != charging ||
      oldDelegate.outline != outline ||
      oldDelegate.fill != fill;
}
