import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../domain/models/device_model.dart';
import 'device_glyph.dart';

/// The rounded square that holds a device glyph in cards.
class DeviceGlyphTile extends StatelessWidget {
  const DeviceGlyphTile({
    required this.model,
    required this.color,
    this.size = 64,
    this.radius = 16,
    this.background,
    super.key,
  });

  final DeviceModel model;
  final Color color;
  final double size;
  final double radius;

  /// Defaults to the raised surface.
  final Color? background;

  @override
  Widget build(BuildContext context) => OiSurface(
    color: background ?? context.kiln.surfaces.surfaceRaised,
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox.square(
      dimension: size,
      child: Center(
        child: DeviceGlyph(model: model, color: color, size: size * 0.625),
      ),
    ),
  );
}
