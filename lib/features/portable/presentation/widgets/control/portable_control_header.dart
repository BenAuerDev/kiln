import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../devices/presentation/widgets/demo/demo_badge.dart';
import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../devices/domain/models/connection_status.dart';
import '../../../../devices/presentation/extensions/connection_status_x.dart';
import '../../../domain/extensions/portable_status_x.dart';
import '../../view_models/portable_control_view_model.dart';
import '../common/portable_battery_indicator.dart';
import '../common/portable_status_line.dart';

/// "kiln" plus "Veazy", then the battery (or the connection state).
class PortableControlHeader extends SignalWidget {
  const PortableControlHeader({required this.vm, super.key});

  final PortableControlViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final connection = vm.connectionStatus.value;
    final status = vm.status.value;
    final name = vm.deviceName.value;
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
                text: status == null
                    ? l10n.portableStatusLine(name, connection.label(l10n))
                    : name,
                trailing: status == null
                    ? null
                    : PortableBatteryIndicator(battery: status.battery),
              ),
            ],
          ),
        ),
        const DemoBadge(),
      ],
    );
  }
}
