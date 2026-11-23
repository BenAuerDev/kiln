import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// "STEP 2 OF 6 · AIR", the step clock and a progress bar.
class WorkflowProgressCard extends StatelessWidget {
  const WorkflowProgressCard({
    required this.headline,
    required this.clock,
    required this.progress,
    super.key,
  });

  final String headline;
  final String clock;

  /// 0–1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return OiSurface(
      color: kiln.surfaces.surface,
      border: OiBorderStyle.solid(kiln.surfaces.border, 1),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: OiLabel.overline(
                  headline.toUpperCase(),
                  semanticsLabel: headline,
                  color: kiln.accent.accentText,
                ),
              ),
              OiLabel.h3(clock),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: kiln.surfaces.track),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: progress,
                    child: ColoredBox(color: kiln.accent.accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
