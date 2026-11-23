import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../domain/extensions/portable_status_x.dart';
import '../../extensions/portable_battery_x.dart';
import '../../view_models/portable_settings_view_model.dart';
import 'portable_device_summary.dart';
import 'portable_find_device_button.dart';

/// Device summary card and "Find my …".
class PortableSettingsOverview extends SignalWidget {
  const PortableSettingsOverview({required this.vm, super.key});

  final PortableSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final name = vm.deviceName.value;
    final status = vm.status.value;
    final finding = vm.finding.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        PortableDeviceSummary(
          name: name,
          model: vm.device.value?.model,
          detail: status?.battery.label(l10n) ?? l10n.portableNoTemperature,
        ),
        PortableFindDeviceButton(
          title: finding
              ? l10n.portableFindingTitle(name)
              : l10n.portableFindTitle(name),
          subtitle: finding
              ? l10n.portableFindingSubtitle
              : l10n.portableFindSubtitle,
          finding: finding,
          enabled: vm.controlsEnabled.value,
          onTap: vm.findDevice,
        ),
      ],
    );
  }
}
