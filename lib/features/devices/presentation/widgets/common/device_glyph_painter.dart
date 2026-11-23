import 'package:flutter/widgets.dart';

import '../../../domain/models/device_model.dart';

/// Original line-art for each model on a 40×40 grid. Deliberately simple
/// shapes, not product imagery.
class DeviceGlyphPainter extends CustomPainter {
  const DeviceGlyphPainter({required this.model, required this.color});

  final DeviceModel model;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 40);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (model) {
      case DeviceModel.volcanoHybrid:
        _volcano(canvas, paint);
      case DeviceModel.venty:
        _venty(canvas, paint);
      case DeviceModel.veazy:
        _veazy(canvas, paint);
      case DeviceModel.craftyPlus:
        _crafty(canvas, paint);
    }
  }

  void _volcano(Canvas canvas, Paint paint) {
    canvas
      ..drawRRect(
        RRect.fromLTRBR(6, 22, 34, 34, const Radius.circular(4)),
        paint,
      )
      ..drawCircle(const Offset(20, 16), 6, paint);
    for (final (x, y) in const [(15.0, 6.0), (20.0, 4.0), (25.0, 6.0)]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..cubicTo(x + 1, y + 1.5, x + 1, y + 2.5, x, y + 4),
        paint,
      );
    }
  }

  void _venty(Canvas canvas, Paint paint) => canvas
    ..drawRRect(RRect.fromLTRBR(13, 5, 27, 35, const Radius.circular(7)), paint)
    ..drawCircle(const Offset(20, 13), 3, paint)
    ..drawLine(const Offset(17, 26), const Offset(23, 26), paint);

  void _veazy(Canvas canvas, Paint paint) => canvas
    ..drawRRect(RRect.fromLTRBR(11, 8, 29, 34, const Radius.circular(9)), paint)
    ..drawCircle(const Offset(20, 16), 3, paint)
    ..drawLine(const Offset(17, 26), const Offset(23, 26), paint);

  void _crafty(Canvas canvas, Paint paint) => canvas
    ..drawRRect(RRect.fromLTRBR(10, 8, 30, 34, const Radius.circular(5)), paint)
    ..drawPath(
      Path()
        ..moveTo(16, 8)
        ..lineTo(16, 5)
        ..lineTo(24, 5)
        ..lineTo(24, 8),
      paint,
    )
    ..drawCircle(const Offset(20, 21), 4, paint);

  @override
  bool shouldRepaint(DeviceGlyphPainter oldDelegate) =>
      oldDelegate.model != model || oldDelegate.color != color;
}
