import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/service_locator.dart';
import '../view_models/devices_view_model.dart';
import '../widgets/devices/devices_demo_entry.dart';
import '../widgets/devices/devices_header.dart';
import '../widgets/devices/devices_notice.dart';
import '../widgets/devices/known_devices_section.dart';
import '../widgets/devices/nearby_section.dart';

class DevicesScreen extends HookWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<DevicesViewModel>());
    useEffect(() {
      unawaited(vm.scan());
      return vm.dispose;
    }, [vm]);

    return ColoredBox(
      color: context.colors.background,
      child: SafeArea(
        child: OiColumn(
          breakpoint: OiBreakpoint.compact,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DevicesHeader(vm: vm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: OiColumn(
                  breakpoint: OiBreakpoint.compact,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  gap: const OiResponsive(28),
                  children: [
                    KnownDevicesSection(vm: vm),
                    NearbySection(vm: vm),
                    DevicesDemoEntry(onTap: vm.openDemo),
                  ],
                ),
              ),
            ),
            const DevicesNotice(),
          ],
        ),
      ),
    );
  }
}
