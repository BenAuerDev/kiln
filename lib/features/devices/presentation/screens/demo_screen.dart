import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/service_locator.dart';
import '../view_models/demo_view_model.dart';
import '../widgets/demo/demo_device_list.dart';
import '../widgets/demo/demo_header.dart';

/// Picks a simulated device for demo mode (docs/plan.md, Demo mode).
class DemoScreen extends HookWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<DemoViewModel>());
    useEffect(() => vm.dispose, [vm]);
    final l10n = getAppLocalizations(context);
    final colors = context.colors;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: OiColumn(
          breakpoint: OiBreakpoint.compact,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DemoHeader(onBack: vm.back),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: OiColumn(
                  breakpoint: OiBreakpoint.compact,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  gap: const OiResponsive(20),
                  children: [
                    Semantics(
                      header: true,
                      child: OiLabel.h2(l10n.devicesDemoTitle),
                    ),
                    OiLabel.body(
                      l10n.devicesDemoIntro,
                      color: colors.textSubtle,
                    ),
                    DemoDeviceList(vm: vm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
