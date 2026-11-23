import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/formatters/temperature_formatter.dart';
import '../../../../core/l10n/get_app_localizations.dart';
import '../../domain/models/volcano_heat_phase.dart';
import '../../../devices/presentation/extensions/connection_status_x.dart';
import '../extensions/volcano_heat_phase_x.dart';
import '../view_models/volcano_control_view_model.dart';
import 'volcano_gauge.dart';
import 'volcano_temperature_readout.dart';

class VolcanoGaugeSection extends SignalWidget {
  const VolcanoGaugeSection({required this.vm, super.key});

  static const size = 300.0;

  final VolcanoControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final status = vm.status.value;
    final phase = vm.phase.value;
    final current = status?.currentTemperature;
    final targetText = status == null
        ? l10n.volcanoNoTemperature
        : TemperatureFormatter.withUnit(status.targetTemperature, l10n);
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VolcanoGauge(
              currentFraction: vm.currentFraction.value,
              targetFraction: vm.targetFraction.value,
              heating: phase == VolcanoHeatPhase.heating,
              ready: phase == VolcanoHeatPhase.ready,
              semanticLabel: l10n.volcanoGaugeLabel,
              size: size,
            ),
            VolcanoTemperatureReadout(
              status:
                  phase?.label(l10n) ?? vm.connectionStatus.value.label(l10n),
              current: current,
              noReading: l10n.volcanoNoTemperature,
              currentSemanticLabel: l10n.volcanoCurrentTemperatureLabel(
                current == null
                    ? l10n.volcanoNoTemperature
                    : TemperatureFormatter.withUnit(current, l10n),
              ),
              targetLine: l10n.volcanoTargetLine(targetText),
            ),
          ],
        ),
      ),
    );
  }
}
