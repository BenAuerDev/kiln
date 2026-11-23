import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/theme/build_context_x.dart';
import '../view_models/volcano_control_view_model.dart';
import 'volcano_toggle_tile.dart';

class VolcanoToggleRow extends SignalWidget {
  const VolcanoToggleRow({required this.vm, super.key});

  final VolcanoControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final kiln = context.kiln;
    final status = vm.status.value;
    final heaterOn = status?.heaterOn ?? false;
    final pumpOn = status?.pumpOn ?? false;
    final enabled = vm.controlsEnabled.value;
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: VolcanoToggleTile(
            icon: OiIcons.flame,
            label: heaterOn ? l10n.volcanoHeaterOn : l10n.volcanoHeaterOff,
            on: heaterOn,
            background: heaterOn
                ? kiln.accent.accent
                : kiln.surfaces.surfaceRaised,
            foreground: heaterOn ? kiln.accent.onAccent : kiln.surfaces.text,
            enabled: enabled,
            onTap: vm.toggleHeater,
          ),
        ),
        Expanded(
          child: VolcanoToggleTile(
            icon: OiIcons.wind,
            label: pumpOn ? l10n.volcanoAirOn : l10n.volcanoAirOff,
            on: pumpOn,
            background: pumpOn ? kiln.surfaces.text : kiln.surfaces.surface,
            foreground: pumpOn ? kiln.surfaces.background : kiln.surfaces.text,
            borderColor: pumpOn ? kiln.surfaces.text : kiln.surfaces.border,
            enabled: enabled,
            onTap: vm.togglePump,
          ),
        ),
      ],
    );
  }
}
