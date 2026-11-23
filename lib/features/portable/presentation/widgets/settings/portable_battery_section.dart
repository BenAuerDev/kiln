import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/portable_settings_view_model.dart';
import 'portable_settings_group.dart';
import 'portable_switch_row.dart';

/// Charge limit and battery saver.
class PortableBatterySection extends SignalWidget {
  const PortableBatterySection({required this.vm, super.key});

  final PortableSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final settings = vm.settings.value;
    final enabled = vm.controlsEnabled.value;
    return PortableSettingsGroup(
      label: l10n.portableBatteryHeading,
      children: [
        PortableSwitchRow(
          title: l10n.portableChargeLimitTitle,
          subtitle: l10n.portableChargeLimitSubtitle,
          value: settings?.ecoCharge ?? false,
          enabled: enabled,
          onChanged: vm.setChargeLimit,
        ),
        PortableSwitchRow(
          title: l10n.portableBatterySaverTitle,
          subtitle: l10n.portableBatterySaverSubtitle,
          value: settings?.ecoVoltage ?? false,
          enabled: enabled,
          onChanged: vm.setBatterySaver,
        ),
      ],
    );
  }
}
