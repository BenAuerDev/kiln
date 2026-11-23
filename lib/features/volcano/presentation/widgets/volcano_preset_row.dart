import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/formatters/temperature_formatter.dart';
import '../../../../core/l10n/get_app_localizations.dart';
import '../view_models/volcano_control_view_model.dart';
import 'volcano_preset_chip.dart';

class VolcanoPresetRow extends SignalWidget {
  const VolcanoPresetRow({required this.vm, super.key});

  final VolcanoControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final target = vm.status.value?.targetTemperature;
    final enabled = vm.controlsEnabled.value;
    return Row(
      spacing: 8,
      children: [
        for (final preset in vm.presets)
          Expanded(
            child: VolcanoPresetChip(
              label: TemperatureFormatter.degrees(preset, l10n),
              semanticLabel: l10n.volcanoPresetLabel(
                TemperatureFormatter.withUnit(preset, l10n),
              ),
              selected: preset == target,
              enabled: enabled,
              onTap: () => vm.selectPreset(preset),
            ),
          ),
      ],
    );
  }
}
