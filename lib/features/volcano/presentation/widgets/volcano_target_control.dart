import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/formatters/temperature_formatter.dart';
import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/theme/build_context_x.dart';
import '../view_models/volcano_control_view_model.dart';
import 'volcano_round_button.dart';

class VolcanoTargetControl extends SignalWidget {
  const VolcanoTargetControl({required this.vm, super.key});

  final VolcanoControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final target = vm.status.value?.targetTemperature;
    final enabled = vm.controlsEnabled.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        VolcanoRoundButton(
          icon: OiIcons.minus,
          semanticLabel: l10n.volcanoLowerTarget,
          onTap: vm.decreaseTarget,
          enabled: enabled,
        ),
        const SizedBox(width: 28),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96),
            child: Column(
              children: [
                OiLabel.h2(
                  target == null
                      ? l10n.volcanoNoTemperature
                      : TemperatureFormatter.degrees(target, l10n),
                ),
                OiLabel.tiny(
                  l10n.volcanoSetTemperature,
                  color: context.kiln.surfaces.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 28),
        VolcanoRoundButton(
          icon: OiIcons.plus,
          semanticLabel: l10n.volcanoRaiseTarget,
          onTap: vm.increaseTarget,
          enabled: enabled,
        ),
      ],
    );
  }
}
