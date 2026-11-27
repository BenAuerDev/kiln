import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../domain/models/portable_battery.dart';
import '../../extensions/portable_battery_x.dart';
import 'portable_battery_painter.dart';
import 'portable_status_line.dart';

/// Battery icon filled to the level, then the percentage: accent fill,
/// red when [PortableBattery.low], a bolt while charging. Reads as
/// "72% battery" / "72% · charging".
class PortableBatteryIndicator extends StatelessWidget {
  const PortableBatteryIndicator({required this.battery, super.key});

  final PortableBattery battery;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final kiln = context.kiln;
    final low = battery.low;
    return Semantics(
      label: battery.label(l10n),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          CustomPaint(
            size: const Size(20, 10),
            painter: PortableBatteryPainter(
              level: battery.percent / 100,
              charging: battery.charging,
              outline: kiln.surfaces.muted,
              fill: low ? kiln.surfaces.low : kiln.accent.accent,
            ),
          ),
          DefaultTextHeightBehavior(
            textHeightBehavior: PortableStatusLine.centredText,
            child: OiLabel.small(
              l10n.portableBatteryPercent(battery.percent),
              color: low ? kiln.surfaces.low : kiln.surfaces.muted,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
