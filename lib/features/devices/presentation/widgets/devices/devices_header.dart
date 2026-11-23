import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/devices_view_model.dart';

class DevicesHeader extends SignalWidget {
  const DevicesHeader({required this.vm, super.key});

  final DevicesViewModel vm;

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
            child: vm.canGoBack.value
                ? OiIconButton(
                    icon: OiIcons.chevronLeft,
                    semanticLabel: l10n.devicesBack,
                    variant: OiButtonVariant.outline,
                    onTap: vm.goBack,
                  )
                : null,
          ),
          Semantics(header: true, child: OiLabel.h4(l10n.devicesTitle)),
          const SizedBox(width: _side),
        ],
      ),
    );
  }
}
