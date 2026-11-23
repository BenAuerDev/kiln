import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/devices_view_model.dart';
import '../common/section_label.dart';
import 'known_device_card.dart';

class KnownDevicesSection extends SignalWidget {
  const KnownDevicesSection({required this.vm, super.key});

  final DevicesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final entries = vm.knownDevices.value;
    final connectingId = vm.connectingId.value;
    final confirmingId = vm.confirmingForgetId.value;
    return OiColumn(
      breakpoint: OiBreakpoint.compact,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: const OiResponsive(12),
      children: [
        SectionLabel(l10n.devicesYours),
        if (entries.isEmpty)
          OiLabel.small(l10n.devicesEmpty, color: context.colors.textSubtle),
        for (final entry in entries)
          KnownDeviceCard(
            key: ValueKey(entry.device.id),
            entry: entry,
            connecting: connectingId == entry.device.id,
            confirmingForget: confirmingId == entry.device.id,
            enabled: connectingId == null,
            onTap: () => vm.openKnown(entry),
            onForget: () => vm.askForget(entry.device.id),
            onConfirmForget: () => vm.confirmForget(entry.device.id),
            onCancelForget: vm.cancelForget,
          ),
        if (vm.activeConnected.value)
          OiButton.ghost(
            label: l10n.devicesDisconnect,
            icon: OiIcons.unplug,
            onTap: vm.disconnect,
          ),
      ],
    );
  }
}
