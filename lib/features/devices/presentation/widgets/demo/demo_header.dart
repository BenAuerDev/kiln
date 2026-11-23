import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';

/// Back button and title of the demo picker.
class DemoHeader extends StatelessWidget {
  const DemoHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  /// Obers enforces a 48 dp minimum touch target on touch devices.
  static const _side = 48.0;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: OiRow(
        breakpoint: OiBreakpoint.compact,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox.square(
            dimension: _side,
            child: OiIconButton(
              icon: OiIcons.chevronLeft,
              semanticLabel: l10n.devicesDemoBack,
              variant: OiButtonVariant.outline,
              onTap: onBack,
            ),
          ),
          Semantics(header: true, child: OiLabel.h4(l10n.devicesDemoBadge)),
          const SizedBox(width: _side),
        ],
      ),
    );
  }
}
