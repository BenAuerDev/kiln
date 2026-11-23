import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../domain/extensions/device_model_x.dart';
import '../../../domain/extensions/discovered_device_x.dart';
import '../../../domain/models/discovered_device.dart';
import '../../extensions/signal_strength_x.dart';
import '../common/device_glyph_tile.dart';

class FoundDeviceCard extends StatelessWidget {
  const FoundDeviceCard({
    required this.device,
    required this.connecting,
    required this.onConnect,
    this.enabled = true,
    super.key,
  });

  final DiscoveredDevice device;
  final bool connecting;
  final bool enabled;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final kiln = context.kiln;
    final name = device.model.displayName;
    return OiSurface(
      color: context.colors.surface,
      border: OiBorderStyle.solid(kiln.accent.accent, 1),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(14),
      child: OiRow(
        breakpoint: OiBreakpoint.compact,
        gap: const OiResponsive(14),
        children: [
          DeviceGlyphTile(
            model: device.model,
            color: kiln.accent.accentText,
            size: 52,
            radius: 14,
          ),
          Expanded(
            child: OiColumn(
              breakpoint: OiBreakpoint.compact,
              crossAxisAlignment: CrossAxisAlignment.start,
              gap: const OiResponsive(2),
              children: [
                OiLabel.bodyStrong(name),
                OiLabel.small(
                  device.signalStrength.label(l10n),
                  color: context.colors.textSubtle,
                ),
              ],
            ),
          ),
          OiButton.primary(
            label: l10n.devicesConnect,
            semanticLabel: l10n.devicesConnectSemantics(name),
            loading: connecting,
            enabled: enabled,
            onTap: onConnect,
          ),
        ],
      ),
    );
  }
}
