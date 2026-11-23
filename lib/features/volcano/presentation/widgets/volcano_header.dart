import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../devices/presentation/widgets/demo/demo_badge.dart';
import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/theme/build_context_x.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../../devices/presentation/extensions/connection_status_x.dart';
import '../view_models/volcano_control_view_model.dart';

class VolcanoHeader extends SignalWidget {
  const VolcanoHeader({required this.vm, super.key});

  final VolcanoControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final kiln = context.kiln;
    final connection = vm.connectionStatus.value;
    final deviceLine = l10n.volcanoDeviceLine(
      vm.deviceName.value ?? l10n.volcanoDefaultName,
      connection.inlineLabel(l10n),
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OiLabel.h4(l10n.appTitle),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox.square(
                    dimension: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connection == ConnectionStatus.connected
                            ? kiln.accent.accent
                            : kiln.surfaces.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: OiLabel.small(
                      deviceLine,
                      color: kiln.surfaces.muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const DemoBadge(),
      ],
    );
  }
}
