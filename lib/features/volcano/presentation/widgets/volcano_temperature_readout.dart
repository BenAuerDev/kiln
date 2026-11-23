import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/theme/build_context_x.dart';
import '../../../../core/widgets/kiln_counting_temperature.dart';

/// Centre of the gauge: status word, current temperature, target line.
class VolcanoTemperatureReadout extends StatelessWidget {
  const VolcanoTemperatureReadout({
    required this.status,
    required this.current,
    required this.noReading,
    required this.currentSemanticLabel,
    required this.targetLine,
    super.key,
  });

  final String status;

  /// °C, or `null` when the device has no reading yet.
  final double? current;
  final String noReading;
  final String currentSemanticLabel;
  final String targetLine;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OiLabel.smallStrong(
          status.toUpperCase(),
          color: kiln.accent.accentText,
        ),
        SizedBox(
          height: 92,
          child: FittedBox(
            child: switch (current) {
              final double celsius => KilnCountingTemperature(
                celsius: celsius,
                semanticsLabel: currentSemanticLabel,
              ),
              null => OiLabel.display(
                noReading,
                semanticsLabel: currentSemanticLabel,
              ),
            },
          ),
        ),
        OiLabel.body(targetLine, color: kiln.surfaces.muted),
      ],
    );
  }
}
