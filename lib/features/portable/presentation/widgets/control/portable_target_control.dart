import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/formatters/temperature_formatter.dart';
import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../view_models/portable_control_view_model.dart';
import '../common/portable_round_button.dart';

/// −/+ around the base target.
class PortableTargetControl extends SignalWidget {
  const PortableTargetControl({required this.vm, super.key});

  final PortableControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final target = vm.status.value?.targetTemperature;
    final enabled = vm.controlsEnabled.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PortableRoundButton(
          icon: OiIcons.minus,
          semanticLabel: l10n.portableLowerTarget,
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
                      ? l10n.portableNoTemperature
                      : TemperatureFormatter.degrees(target, l10n),
                ),
                OiLabel.tiny(
                  l10n.portableSetTemperature,
                  color: context.kiln.surfaces.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 28),
        PortableRoundButton(
          icon: OiIcons.plus,
          semanticLabel: l10n.portableRaiseTarget,
          onTap: vm.increaseTarget,
          enabled: enabled,
        ),
      ],
    );
  }
}
