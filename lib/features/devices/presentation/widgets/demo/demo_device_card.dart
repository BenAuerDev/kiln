import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../domain/extensions/device_model_x.dart';
import '../../../domain/models/device_model.dart';
import '../common/device_glyph_tile.dart';

/// One simulated device on the demo picker.
class DemoDeviceCard extends StatelessWidget {
  const DemoDeviceCard({
    required this.model,
    required this.starting,
    required this.enabled,
    required this.onStart,
    super.key,
  });

  final DeviceModel model;
  final bool starting;
  final bool enabled;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final colors = context.colors;
    final name = model.displayName;
    return OiSurface(
      border: OiBorderStyle.solid(colors.border, 1),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(14),
      child: OiRow(
        breakpoint: OiBreakpoint.compact,
        gap: const OiResponsive(14),
        children: [
          DeviceGlyphTile(model: model, color: colors.text),
          Expanded(
            child: OiColumn(
              breakpoint: OiBreakpoint.compact,
              crossAxisAlignment: CrossAxisAlignment.start,
              gap: const OiResponsive(4),
              children: [
                OiLabel.bodyStrong(name),
                OiLabel.small(
                  model.isPortable
                      ? l10n.devicesDemoPortableDescription
                      : l10n.devicesDemoVolcanoDescription,
                  color: colors.textSubtle,
                ),
              ],
            ),
          ),
          OiButton.primary(
            label: l10n.devicesDemoStart,
            semanticLabel: l10n.devicesDemoStartSemantics(name),
            loading: starting,
            enabled: enabled,
            onTap: onStart,
          ),
        ],
      ),
    );
  }
}
