import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

class WelcomeBullet extends StatelessWidget {
  const WelcomeBullet({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => OiRow(
    breakpoint: OiBreakpoint.compact,
    gap: const OiResponsive(12),
    children: [
      OiIcon.decorative(
        icon: icon,
        size: 20,
        color: context.kiln.accent.accentText,
      ),
      Expanded(child: OiLabel.small(text, color: context.colors.text)),
    ],
  );
}
