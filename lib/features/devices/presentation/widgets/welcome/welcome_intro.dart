import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import 'welcome_bullet.dart';

/// The Bluetooth explainer shown before the system permission prompt.
class WelcomeIntro extends StatelessWidget {
  const WelcomeIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return OiColumn(
      breakpoint: OiBreakpoint.compact,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: const OiResponsive(12),
      children: [
        OiLabel.h1(l10n.welcomeTitle),
        OiLabel.body(l10n.welcomeBody, color: context.colors.textSubtle),
        const SizedBox(height: 0),
        WelcomeBullet(icon: OiIcons.lock, text: l10n.welcomePointPrivacy),
        WelcomeBullet(icon: OiIcons.rotateCw, text: l10n.welcomePointReconnect),
        WelcomeBullet(
          icon: OiIcons.toggleRight,
          text: l10n.welcomePointDevices,
        ),
      ],
    );
  }
}
