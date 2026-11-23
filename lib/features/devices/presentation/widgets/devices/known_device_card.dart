import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../domain/extensions/device_model_x.dart';
import '../../../domain/models/connection_status.dart';
import '../../../domain/models/known_device_entry.dart';
import '../../extensions/known_device_entry_x.dart';
import '../common/device_glyph_tile.dart';

class KnownDeviceCard extends StatelessWidget {
  const KnownDeviceCard({
    required this.entry,
    required this.connecting,
    required this.confirmingForget,
    required this.onTap,
    required this.onForget,
    required this.onConfirmForget,
    required this.onCancelForget,
    this.enabled = true,
    super.key,
  });

  final KnownDeviceEntry entry;
  final bool connecting;
  final bool confirmingForget;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onForget;
  final VoidCallback onConfirmForget;
  final VoidCallback onCancelForget;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final kiln = context.kiln;
    final colors = context.colors;
    final name = entry.device.model.displayName;
    final status = entry.status;
    final connected = status == ConnectionStatus.connected;
    final busy =
        connecting ||
        status == ConnectionStatus.connecting ||
        status == ConnectionStatus.reconnecting;

    return OiSurface(
      color: colors.surface,
      border: OiBorderStyle.solid(
        entry.isActive ? kiln.accent.accent : colors.border,
        1,
      ),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(14),
      child: OiColumn(
        breakpoint: OiBreakpoint.compact,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        gap: const OiResponsive(12),
        children: [
          OiRow(
            breakpoint: OiBreakpoint.compact,
            gap: const OiResponsive(8),
            children: [
              Expanded(
                child: OiTappable(
                  onTap: onTap,
                  enabled: enabled && !busy,
                  semanticLabel: l10n.commonSemanticsWithDetail(
                    connected
                        ? l10n.devicesOpenSemantics(name)
                        : l10n.devicesConnectSemantics(name),
                    entry.subtitle(l10n),
                  ),
                  child: OiRow(
                    breakpoint: OiBreakpoint.compact,
                    gap: const OiResponsive(14),
                    children: [
                      DeviceGlyphTile(
                        model: entry.device.model,
                        color: entry.isActive
                            ? kiln.accent.accentText
                            : colors.text,
                      ),
                      Expanded(
                        child: OiColumn(
                          breakpoint: OiBreakpoint.compact,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          gap: const OiResponsive(4),
                          children: [
                            OiLabel.bodyStrong(name),
                            OiRow(
                              breakpoint: OiBreakpoint.compact,
                              gap: const OiResponsive(6),
                              children: [
                                if (entry.isActive)
                                  OiStatusDot(
                                    label: entry.subtitle(l10n),
                                    color: connected
                                        ? kiln.accent.accent
                                        : colors.textSubtle,
                                    pulsing: busy,
                                  ),
                                Flexible(
                                  child: OiLabel.small(
                                    entry.subtitle(l10n),
                                    color: colors.textSubtle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (connected) OiBadge.filled(label: l10n.devicesActive),
              OiIconButton(
                icon: OiIcons.trash2,
                semanticLabel: l10n.devicesForgetSemantics(name),
                size: OiButtonSize.small,
                enabled: enabled,
                onTap: onForget,
              ),
            ],
          ),
          if (confirmingForget)
            OiRow(
              breakpoint: OiBreakpoint.compact,
              gap: const OiResponsive(8),
              children: [
                Expanded(child: OiLabel.small(l10n.devicesForgetConfirm)),
                OiButton.ghost(
                  label: l10n.commonCancel,
                  size: OiButtonSize.small,
                  onTap: onCancelForget,
                ),
                OiButton.destructive(
                  label: l10n.devicesForget,
                  semanticLabel: l10n.devicesForgetSemantics(name),
                  size: OiButtonSize.small,
                  onTap: onConfirmForget,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
