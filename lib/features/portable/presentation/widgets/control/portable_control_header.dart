import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../devices/domain/models/connection_status.dart';
import '../../../../devices/presentation/extensions/connection_status_x.dart';
import '../../../domain/extensions/portable_status_x.dart';
import '../../extensions/portable_battery_x.dart';
import '../../view_models/portable_control_view_model.dart';
import '../common/portable_status_line.dart';

/// "kiln" plus "Veazy · 72% battery".
class PortableControlHeader extends SignalWidget {
  const PortableControlHeader({required this.vm, super.key});

  final PortableControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final connection = vm.connectionStatus.value;
    final status = vm.status.value;
    final detail = status == null
        ? connection.label(l10n)
        : status.battery.label(l10n);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              OiLabel.h4(l10n.appTitle),
              PortableStatusLine(
                active: connection == ConnectionStatus.connected,
                text: l10n.portableStatusLine(vm.deviceName.value, detail),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
