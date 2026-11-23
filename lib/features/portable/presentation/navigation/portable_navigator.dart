import 'package:go_router/go_router.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/router/navigator_keys.dart';
import '../../../../core/router/route_paths.dart';
import '../view_models/portable_tab.dart';
import '../widgets/settings/portable_forget_dialog.dart';

/// Navigation and dialogs of the portable view models, injectable so they
/// can be tested without a router.
class PortableNavigator {
  void goToTab(PortableTab tab) => _go(switch (tab) {
    PortableTab.control => RoutePaths.portableControl,
    PortableTab.setup => RoutePaths.portableSetup,
    PortableTab.devices => RoutePaths.devices,
  });

  void openSettings() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).push(RoutePaths.portableSettings);
  }

  void back() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.portableSetup);
    }
  }

  void goToDevices() => _go(RoutePaths.devices);

  /// Resolves to `true` when the user confirmed.
  Future<bool> confirmForget(String deviceName) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return false;
    final confirmed = await showOiDialog<bool>(
      context,
      builder: (context, close) => PortableForgetDialog(
        deviceName: deviceName,
        onCancel: () => close(false),
        onConfirm: () => close(true),
      ),
    );
    return confirmed ?? false;
  }

  void _go(String path) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).go(path);
  }
}
