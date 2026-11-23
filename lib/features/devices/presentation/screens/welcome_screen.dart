import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/service_locator.dart';
import '../view_models/welcome_view_model.dart';
import '../widgets/welcome/welcome_content.dart';
import '../widgets/welcome/welcome_footer.dart';
import '../widgets/welcome/welcome_header.dart';
import '../widgets/welcome/welcome_radar.dart';

class WelcomeScreen extends HookWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<WelcomeViewModel>());
    useEffect(() => vm.dispose, [vm]);

    return ColoredBox(
      color: context.colors.background,
      child: SafeArea(
        child: OiColumn(
          breakpoint: OiBreakpoint.compact,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WelcomeHeader(vm: vm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: OiColumn(
                  breakpoint: OiBreakpoint.compact,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  gap: const OiResponsive(36),
                  children: [
                    Center(child: WelcomeRadar(vm: vm)),
                    WelcomeContent(vm: vm),
                  ],
                ),
              ),
            ),
            WelcomeFooter(vm: vm),
          ],
        ),
      ),
    );
  }
}
