import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/service_locator.dart';
import '../../view_models/demo_badge_view_model.dart';

/// "Demo ×" in a device header while a demo device is active; tapping it
/// leaves the demo. Self-contained (ARCHITECTURE.md, screens and widgets):
/// all its state lives in repository signals, so it owns its view model.
class DemoBadge extends HookWidget {
  const DemoBadge({this.padding = EdgeInsets.zero, super.key});

  /// Applied only while the badge is visible.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<DemoBadgeViewModel>());
    useEffect(() => vm.dispose, [vm]);
    return SignalBuilder(
      builder: (context) {
        if (!vm.visible.value) return const SizedBox.shrink();
        final l10n = getAppLocalizations(context);
        return Padding(
          padding: padding,
          child: OiButton.soft(
            label: l10n.devicesDemoBadge,
            icon: OiIcons.x,
            iconPosition: OiIconPosition.trailing,
            size: OiButtonSize.small,
            semanticLabel: l10n.devicesDemoLeaveSemantics,
            onTap: vm.leave,
          ),
        );
      },
    );
  }
}
