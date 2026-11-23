import 'package:flutter/widgets.dart';

import '../../../domain/models/device_model.dart';
import 'device_glyph_painter.dart';

class DeviceGlyph extends StatelessWidget {
  const DeviceGlyph({
    required this.model,
    required this.color,
    this.size = 40,
    super.key,
  });

  final DeviceModel model;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: DeviceGlyphPainter(model: model, color: color),
    ),
  );
}
