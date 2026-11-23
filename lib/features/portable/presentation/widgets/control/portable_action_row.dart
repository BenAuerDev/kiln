import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../domain/extensions/portable_status_x.dart';
import '../../../domain/models/heater_mode.dart';
import '../../view_models/portable_control_view_model.dart';
import 'portable_action_tile.dart';

/// Heater and Boost buttons.
class PortableActionRow extends SignalWidget {
  const PortableActionRow({required this.vm, super.key});

  final PortableControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final kiln = context.kiln;
    final status = vm.status.value;
    final heaterOn = (status?.heaterMode ?? HeaterMode.off) != HeaterMode.off;
    final boostOn = status?.boostActive ?? false;
    final enabled = vm.controlsEnabled.value;
    final boostLabel = switch (status?.heaterMode) {
      HeaterMode.boost => l10n.portableBoostOn(status!.boostOffset),
      HeaterMode.superboost => l10n.portableSuperBoostOn(
        status!.superBoostTotal,
      ),
      _ => l10n.portableBoost,
    };
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: PortableActionTile(
            icon: OiIcons.flame,
            label: heaterOn ? l10n.portableHeaterOn : l10n.portableHeaterOff,
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
          child: PortableActionTile(
            icon: OiIcons.zap,
            label: boostLabel,
            semanticLabel: boostLabel,
            on: boostOn,
            background: boostOn ? kiln.surfaces.text : kiln.surfaces.surface,
            foreground: boostOn ? kiln.surfaces.background : kiln.surfaces.text,
            borderColor: boostOn ? kiln.surfaces.text : kiln.surfaces.border,
            enabled: enabled,
            onTap: vm.toggleBoost,
          ),
        ),
      ],
    );
  }
}
