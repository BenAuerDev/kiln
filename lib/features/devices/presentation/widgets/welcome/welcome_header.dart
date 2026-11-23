import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/welcome_view_model.dart';
import 'language_switch.dart';

class WelcomeHeader extends SignalWidget {
  const WelcomeHeader({required this.vm, super.key});

  final WelcomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: OiRow(
        breakpoint: OiBreakpoint.compact,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OiLabel.h3(l10n.appTitle),
          LanguageSwitch(
            selected: vm.languageCode.value,
            onChanged: vm.selectLanguage,
            semanticLabel: l10n.welcomeLanguageLabel,
          ),
        ],
      ),
    );
  }
}
