import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../common/portable_round_button.dart';

/// Back button and centred title.
class PortableSettingsHeader extends StatelessWidget {
  const PortableSettingsHeader({
    required this.title,
    required this.backLabel,
    required this.onBack,
    super.key,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      PortableRoundButton(
        icon: OiIcons.chevronLeft,
        semanticLabel: backLabel,
        onTap: onBack,
        size: 44,
        iconSize: 20,
      ),
      Expanded(
        child: Semantics(
          header: true,
          child: OiLabel.h4(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      const SizedBox(width: 44),
    ],
  );
}
