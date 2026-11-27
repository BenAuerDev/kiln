import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/theme/build_context_x.dart';
import '../../../../portable/presentation/widgets/common/portable_card.dart';
import '../../view_models/ramp_editor_view_model.dart';

/// What the ramp does: `170–190°`, then `+5° every 2 min · 8 min`.
class RampPreview extends SignalWidget {
  const RampPreview({required this.vm, super.key});

  final RampEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    return MergeSemantics(
      child: PortableCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 12,
          children: [
            OiIcon.decorative(
              icon: OiIcons.trendingUp,
              size: 22,
              color: kiln.accent.accentText,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  OiLabel.h3(vm.range.value),
                  OiLabel.small(vm.summary.value, color: kiln.surfaces.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
