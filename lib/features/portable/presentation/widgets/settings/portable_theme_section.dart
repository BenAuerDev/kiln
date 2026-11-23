import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../../../../devices/domain/models/device_finish.dart';
import '../../../../devices/domain/models/finish_preference.dart';
import '../../../../devices/presentation/extensions/device_finish_x.dart';
import '../../view_models/portable_settings_view_model.dart';
import '../common/portable_section_label.dart';
import 'portable_finish_swatch.dart';
import 'portable_match_device_tile.dart';

/// App theme for this device: "Match my device" or a fixed finish.
class PortableThemeSection extends SignalWidget {
  const PortableThemeSection({required this.vm, super.key});

  /// Colour wheel of the "Match my device" option.
  static const _wheel = [
    DeviceFinish.blue,
    DeviceFinish.pink,
    DeviceFinish.ember,
    DeviceFinish.mono,
  ];

  final PortableSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final brightness = OiTheme.of(context).brightness;
    final device = vm.device.value;
    final name = vm.deviceName.value;
    final preference = device?.finishPreference ?? const MatchDevice();
    final detected = device?.detectedFinish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        PortableSectionLabel(l10n.portableThemeHeading),
        PortableMatchDeviceTile(
          title: l10n.portableThemeMatchTitle,
          subtitle: detected == null
              ? l10n.portableThemeMatchUnknown
              : l10n.portableThemeMatchDetected(detected.label(l10n), name),
          wheelColors: [
            for (final finish in _wheel)
              finish.tokens.resolve(brightness).accent,
          ],
          selected: preference is MatchDevice,
          onTap: () => vm.selectFinish(const MatchDevice()),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              for (final finish in vm.finishes)
                Expanded(
                  child: PortableFinishSwatch(
                    label: finish.label(l10n),
                    semanticLabel: l10n.portableThemeSwatchLabel(
                      finish.label(l10n),
                    ),
                    tokens: finish.tokens.resolve(brightness),
                    selected: preference == FixedFinish(finish),
                    onTap: () => vm.selectFinish(FixedFinish(finish)),
                  ),
                ),
            ],
          ),
        ),
        OiLabel.small(
          l10n.portableThemeNote(name),
          color: context.kiln.surfaces.muted,
        ),
      ],
    );
  }
}
