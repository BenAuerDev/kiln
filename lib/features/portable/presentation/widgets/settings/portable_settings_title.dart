import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/portable_settings_view_model.dart';
import 'portable_settings_header.dart';

/// [PortableSettingsHeader] bound to the device name.
class PortableSettingsTitle extends SignalWidget {
  const PortableSettingsTitle({required this.vm, super.key});

  final PortableSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return PortableSettingsHeader(
      title: l10n.portableOpenSettings(vm.deviceName.value),
      backLabel: l10n.portableSettingsBack,
      onBack: vm.back,
    );
  }
}
