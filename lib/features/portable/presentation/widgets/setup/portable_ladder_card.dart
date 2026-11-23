import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/formatters/temperature_formatter.dart';
import '../../../../../core/l10n/get_app_localizations.dart';
import '../../extensions/portable_ladder_x.dart';
import '../../view_models/portable_setup_view_model.dart';
import '../common/portable_card.dart';
import 'portable_ladder_row.dart';
import 'portable_scale_bar.dart';

/// Scale bar plus the Base / Boost / Superboost rows.
class PortableLadderCard extends SignalWidget {
  const PortableLadderCard({required this.vm, super.key});

  final PortableSetupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final ladder = vm.ladder.value;
    final status = vm.status.value;
    final enabled = vm.controlsEnabled.value;
    final none = l10n.portableNoTemperature;

    String degrees(int celsius) => TemperatureFormatter.degrees(celsius, l10n);
    String offset(int? value) =>
        value == null ? none : l10n.portableOffset(value);

    return PortableCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortableScaleBar(
            basePosition: ladder?.basePosition ?? 0,
            boostPosition: ladder?.boostPosition ?? 0,
            superBoostPosition: ladder?.superBoostPosition ?? 0,
            minLabel: degrees(vm.scaleMinimum),
            maxLabel: degrees(vm.scaleMaximum),
            semanticLabel: ladder?.scaleLabel(l10n) ?? none,
          ),
          PortableLadderRow(
            icon: OiIcons.power,
            name: l10n.portableBaseName,
            hint: l10n.portableBaseHint,
            value: ladder == null ? none : degrees(ladder.base),
            sub: l10n.portableBaseSub,
            lowerLabel: l10n.portableLowerBase,
            raiseLabel: l10n.portableRaiseBase,
            onLower: vm.lowerBase,
            onRaise: vm.raiseBase,
            enabled: enabled,
          ),
          PortableLadderRow(
            icon: OiIcons.zap,
            name: l10n.portableBoostName,
            hint: l10n.portableBoostHint,
            value: offset(status?.boostOffset),
            sub: ladder?.boostTargetLabel(l10n) ?? none,
            subAccent: true,
            lowerLabel: l10n.portableLowerBoost,
            raiseLabel: l10n.portableRaiseBoost,
            onLower: vm.lowerBoost,
            onRaise: vm.raiseBoost,
            enabled: enabled,
          ),
          PortableLadderRow(
            icon: OiIcons.chevronsUp,
            name: l10n.portableSuperBoostName,
            hint: l10n.portableSuperBoostHint,
            value: offset(status?.superBoostOffset),
            sub: ladder?.superBoostTargetLabel(l10n) ?? none,
            subAccent: true,
            lowerLabel: l10n.portableLowerSuperBoost,
            raiseLabel: l10n.portableRaiseSuperBoost,
            onLower: vm.lowerSuperBoost,
            onRaise: vm.raiseSuperBoost,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
