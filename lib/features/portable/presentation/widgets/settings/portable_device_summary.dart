import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../../devices/domain/models/device_model.dart';
import '../../../../devices/presentation/widgets/common/device_glyph.dart';
import '../common/portable_card.dart';

/// Device glyph with glow, name and a detail line (the battery).
class PortableDeviceSummary extends StatelessWidget {
  const PortableDeviceSummary({
    required this.name,
    required this.detail,
    required this.model,
    super.key,
  });

  final String name;
  final Widget detail;
  final DeviceModel? model;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final model = this.model;
    return PortableCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        spacing: 16,
        children: [
          SizedBox.square(
            dimension: 72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: kiln.surfaces.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: kiln.accent.glow, blurRadius: 24)],
              ),
              child: Center(
                child: model == null
                    ? null
                    : DeviceGlyph(
                        model: model,
                        color: kiln.accent.accentText,
                        size: 42,
                      ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                OiLabel.bodyStrong(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                detail,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
