import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/l10n/get_app_localizations.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../view_models/portable_settings_view_model.dart';
import '../widgets/settings/portable_battery_section.dart';
import '../widgets/settings/portable_device_section.dart';
import '../widgets/settings/portable_forget_button.dart';
import '../widgets/settings/portable_settings_overview.dart';
import '../widgets/settings/portable_settings_title.dart';
import '../widgets/settings/portable_theme_section.dart';

/// Device settings (`design/Finish.dc.html`, without "Run device check").
class PortableSettingsScreen extends HookWidget {
  const PortableSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<PortableSettingsViewModel>());
    useEffect(() => vm.dispose, [vm]);
    final l10n = getAppLocalizations(context);
    return ColoredBox(
      color: context.kiln.surfaces.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: OiPage(
            breakpoint: OiBreakpoint.compact,
            children: [
              PortableSettingsTitle(vm: vm),
              const SizedBox(height: 20),
              PortableSettingsOverview(vm: vm),
              const SizedBox(height: 24),
              PortableBatterySection(vm: vm),
              const SizedBox(height: 24),
              PortableDeviceSection(vm: vm),
              const SizedBox(height: 24),
              PortableThemeSection(vm: vm),
              const SizedBox(height: 28),
              PortableForgetButton(
                label: l10n.portableForgetDevice,
                onTap: vm.forgetDevice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
