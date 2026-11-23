import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/welcome_step.dart';
import '../../view_models/welcome_view_model.dart';
import 'found_device_card.dart';

class WelcomeScanSection extends SignalWidget {
  const WelcomeScanSection({required this.vm, super.key});

  final WelcomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final state = vm.scanState.value;
    final found = vm.found.value;
    final connectingId = vm.connectingId.value;
    return OiColumn(
      breakpoint: OiBreakpoint.compact,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: const OiResponsive(16),
      children: [
        Semantics(
          liveRegion: true,
          child: OiLabel.h1(switch (state) {
            WelcomeScanState.looking => l10n.welcomeScanLooking,
            WelcomeScanState.found => l10n.welcomeScanFound(found.length),
            WelcomeScanState.nothing => l10n.welcomeScanNothing,
          }),
        ),
        OiLabel.body(l10n.welcomeScanHint, color: context.colors.textSubtle),
        for (final device in found)
          FoundDeviceCard(
            key: ValueKey(device.id),
            device: device,
            connecting: connectingId == device.id,
            enabled: connectingId == null,
            onConnect: () => vm.connect(device),
          ),
        if (state == WelcomeScanState.nothing)
          OiButton.outline(
            label: l10n.welcomeScanAgain,
            icon: OiIcons.rotateCw,
            onTap: vm.scanAgain,
          ),
      ],
    );
  }
}
