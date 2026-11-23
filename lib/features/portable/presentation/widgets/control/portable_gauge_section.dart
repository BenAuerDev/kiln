import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/formatters/temperature_formatter.dart';
import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../devices/presentation/extensions/connection_status_x.dart';
import '../../extensions/portable_heat_phase_x.dart';
import '../../view_models/portable_control_view_model.dart';
import '../../../domain/models/portable_heat_phase.dart';
import 'portable_gauge.dart';
import 'portable_heat_wisps.dart';
import 'portable_temperature_readout.dart';

/// Gauge with wisps and the readout. Without a live reading (Venty and Veazy
/// often send none) the big number shows the target instead.
class PortableGaugeSection extends SignalWidget {
  const PortableGaugeSection({required this.vm, super.key});

  static const size = 300.0;

  final PortableControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final phase = vm.phase.value;
    final current = vm.status.value?.currentTemperature;
    final target = vm.activeTarget.value;
    final heating = phase == PortableHeatPhase.heating;
    final none = l10n.portableNoTemperature;
    final targetWithUnit = target == null
        ? none
        : TemperatureFormatter.withUnit(target, l10n);

    final String big;
    final String bigSemantics;
    final String line;
    if (current != null) {
      big = TemperatureFormatter.degrees(current, l10n);
      bigSemantics = l10n.portableCurrentTemperatureLabel(
        TemperatureFormatter.withUnit(current, l10n),
      );
      line = l10n.portableTargetLine(targetWithUnit);
    } else {
      big = target == null ? none : TemperatureFormatter.degrees(target, l10n);
      bigSemantics = l10n.portableTargetTemperatureLabel(targetWithUnit);
      line = l10n.portableTargetOnlyLine;
    }

    return Center(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (heating) const PortableHeatWisps(size: size),
            PortableGauge(
              progress: vm.gaugeProgress.value,
              targetPosition: vm.targetPosition.value,
              heating: heating,
              ready: phase == PortableHeatPhase.ready,
              semanticLabel: l10n.portableGaugeLabel,
              size: size,
            ),
            PortableTemperatureReadout(
              status:
                  phase?.label(l10n) ?? vm.connectionStatus.value.label(l10n),
              temperature: big,
              temperatureSemanticLabel: bigSemantics,
              line: line,
            ),
          ],
        ),
      ),
    );
  }
}
