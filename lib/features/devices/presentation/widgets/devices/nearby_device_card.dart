import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../domain/extensions/device_model_x.dart';
import '../../../domain/extensions/discovered_device_x.dart';
import '../../../domain/models/discovered_device.dart';
import '../../extensions/signal_strength_x.dart';
import '../common/device_glyph_tile.dart';

class NearbyDeviceCard extends StatelessWidget {
  const NearbyDeviceCard({
    required this.device,
    required this.connecting,
    required this.onPair,
    this.enabled = true,
    super.key,
  });

  final DiscoveredDevice device;
  final bool connecting;
  final bool enabled;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final colors = context.colors;
    final name = device.model.displayName;
    return OiSurface(
      border: OiBorderStyle.dashed(colors.border, 1),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(14),
      child: OiRow(
        breakpoint: OiBreakpoint.compact,
        gap: const OiResponsive(14),
        children: [
          DeviceGlyphTile(
            model: device.model,
            color: colors.textSubtle,
            background: colors.surface,
          ),
          Expanded(
            child: OiColumn(
              breakpoint: OiBreakpoint.compact,
              crossAxisAlignment: CrossAxisAlignment.start,
              gap: const OiResponsive(4),
              children: [
                OiLabel.bodyStrong(name),
                OiLabel.small(
                  l10n.devicesNearbySubtitle(device.signalStrength.label(l10n)),
                  color: colors.textSubtle,
                ),
              ],
            ),
          ),
          OiButton.primary(
            label: l10n.devicesPair,
            semanticLabel: l10n.devicesConnectSemantics(name),
            loading: connecting,
            enabled: enabled,
            onTap: onPair,
          ),
        ],
      ),
    );
  }
}
