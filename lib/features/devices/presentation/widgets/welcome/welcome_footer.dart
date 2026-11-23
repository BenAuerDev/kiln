import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/welcome_step.dart';
import '../../view_models/welcome_view_model.dart';

class WelcomeFooter extends SignalWidget {
  const WelcomeFooter({required this.vm, super.key});

  final WelcomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: OiColumn(
        breakpoint: OiBreakpoint.compact,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        gap: const OiResponsive(8),
        children: [
          switch (vm.step.value) {
            WelcomeStep.intro => OiButton.primary(
              label: l10n.welcomeContinue,
              size: OiButtonSize.large,
              fullWidth: true,
              onTap: vm.start,
            ),
            WelcomeStep.scan => OiButton.ghost(
              label: l10n.welcomeSkip,
              fullWidth: true,
              enabled: vm.connectingId.value == null,
              onTap: vm.skip,
            ),
          },
          OiLabel.tiny(
            l10n.commonUnofficialNotice,
            textAlign: TextAlign.center,
            color: context.colors.textSubtle,
          ),
        ],
      ),
    );
  }
}
