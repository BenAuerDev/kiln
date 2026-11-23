import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../../devices/domain/models/connection_status.dart';
import '../../../../devices/presentation/extensions/connection_status_x.dart';
import '../../../domain/extensions/portable_status_x.dart';
import '../../extensions/portable_battery_x.dart';
import '../../view_models/portable_setup_view_model.dart';
import '../common/portable_round_button.dart';
import '../common/portable_status_line.dart';

/// Device name, connection and battery, settings button and intro text.
class PortableSetupHeader extends SignalWidget {
  const PortableSetupHeader({required this.vm, super.key});

  final PortableSetupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final name = vm.deviceName.value;
    final connection = vm.connectionStatus.value;
    final status = vm.status.value;
    final connectionLabel = connection.label(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Semantics(
                    header: true,
                    child: OiLabel.h2(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PortableStatusLine(
                    active: connection == ConnectionStatus.connected,
                    text: status == null
                        ? connectionLabel
                        : l10n.portableStatusLine(
                            connectionLabel,
                            status.battery.label(l10n),
                          ),
                  ),
                ],
              ),
            ),
            PortableRoundButton(
              icon: OiIcons.settings,
              semanticLabel: l10n.portableOpenSettings(name),
              onTap: vm.openSettings,
              size: 44,
              iconSize: 20,
            ),
          ],
        ),
        OiLabel.small(
          l10n.portableSetupIntro(name),
          color: context.kiln.surfaces.muted,
        ),
      ],
    );
  }
}
