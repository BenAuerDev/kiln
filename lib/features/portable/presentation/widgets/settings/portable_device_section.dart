import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/portable_settings_view_model.dart';
import 'portable_settings_group.dart';
import 'portable_switch_row.dart';
import 'portable_unit_row.dart';

/// Vibrate when ready, boost on LEDs and the temperature unit.
class PortableDeviceSection extends SignalWidget {
  const PortableDeviceSection({required this.vm, super.key});

  final PortableSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final settings = vm.settings.value;
    final enabled = vm.controlsEnabled.value;
    return PortableSettingsGroup(
      label: l10n.portableDeviceHeading,
      children: [
        PortableSwitchRow(
          title: l10n.portableVibrateTitle,
          subtitle: l10n.portableVibrateSubtitle,
          value: settings?.vibrateWhenReady ?? false,
          enabled: enabled,
          onChanged: vm.setVibrateWhenReady,
        ),
        PortableSwitchRow(
          title: l10n.portableBoostLedsTitle,
          subtitle: l10n.portableBoostLedsSubtitle,
          value: settings?.boostVisualisation ?? false,
          enabled: enabled,
          onChanged: vm.setBoostOnLeds,
        ),
        PortableUnitRow(
          title: l10n.portableUnitTitle,
          celsiusLabel: l10n.portableUnitCelsius,
          fahrenheitLabel: l10n.portableUnitFahrenheit,
          fahrenheit: settings?.fahrenheit ?? false,
          enabled: enabled,
          onChanged: vm.setFahrenheit,
        ),
      ],
    );
  }
}
