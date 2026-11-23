import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';

/// One radio segment of the quick setups control: name over range.
class PortableQuickSetupOption extends StatelessWidget {
  const PortableQuickSetupOption({
    required this.name,
    required this.range,
    required this.checked,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final String name;
  final String range;
  final bool checked;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final radius = BorderRadius.circular(12);
    final foreground = checked ? kiln.accent.onAccent : kiln.surfaces.text;
    return OiTappable(
      role: OiTappableRole.radio,
      checked: checked,
      inMutuallyExclusiveGroup: true,
      semanticLabel: getAppLocalizations(
        context,
      ).commonSemanticsWithDetail(name, range),
      enabled: enabled,
      onTap: onTap,
      clipBorderRadius: radius,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: checked ? kiln.accent.accent : null,
          borderRadius: radius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OiLabel.smallStrong(
              name,
              color: foreground,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Opacity(
              opacity: 0.8,
              child: OiLabel.tiny(range, color: foreground, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
