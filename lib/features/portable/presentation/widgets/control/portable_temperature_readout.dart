import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// Centre of the gauge: status word, big temperature, target line.
class PortableTemperatureReadout extends StatelessWidget {
  const PortableTemperatureReadout({
    required this.status,
    required this.temperature,
    required this.temperatureSemanticLabel,
    required this.line,
    super.key,
  });

  final String status;
  final String temperature;
  final String temperatureSemanticLabel;
  final String line;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OiLabel.smallStrong(
          status.toUpperCase(),
          semanticsLabel: status,
          color: kiln.accent.accentText,
        ),
        SizedBox(
          height: 92,
          child: FittedBox(
            child: OiLabel.display(
              temperature,
              semanticsLabel: temperatureSemanticLabel,
            ),
          ),
        ),
        OiLabel.body(line, color: kiln.surfaces.muted),
      ],
    );
  }
}
