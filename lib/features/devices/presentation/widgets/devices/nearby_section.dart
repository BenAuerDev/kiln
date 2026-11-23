import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/devices_view_model.dart';
import '../common/section_label.dart';
import 'nearby_device_card.dart';
import 'scan_pulse.dart';

class NearbySection extends SignalWidget {
  const NearbySection({required this.vm, super.key});

  final DevicesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final scanning = vm.scanning.value;
    final nearby = vm.nearby.value;
    final connectingId = vm.connectingId.value;
    return OiColumn(
      breakpoint: OiBreakpoint.compact,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: const OiResponsive(12),
      children: [
        OiRow(
          breakpoint: OiBreakpoint.compact,
          gap: const OiResponsive(12),
          children: [
            ScanPulse(active: scanning),
            Expanded(
              child: SectionLabel(
                scanning ? l10n.devicesScanning : l10n.devicesNearby,
              ),
            ),
            if (!scanning)
              OiButton.ghost(
                label: l10n.devicesScan,
                icon: OiIcons.rotateCw,
                size: OiButtonSize.small,
                onTap: vm.scan,
              ),
          ],
        ),
        for (final device in nearby)
          NearbyDeviceCard(
            key: ValueKey(device.id),
            device: device,
            connecting: connectingId == device.id,
            enabled: connectingId == null,
            onPair: () => vm.pair(device),
          ),
        if (nearby.isEmpty && !scanning)
          OiLabel.small(
            l10n.devicesNoneNearby,
            color: context.colors.textSubtle,
          ),
      ],
    );
  }
}
