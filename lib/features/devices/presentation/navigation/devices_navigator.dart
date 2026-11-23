import 'package:go_router/go_router.dart';

import '../../../../core/router/navigator_keys.dart';
import '../../../../core/router/route_paths.dart';
import '../../domain/extensions/device_model_x.dart';
import '../../domain/models/device_model.dart';

/// Navigation used by the devices view models, injectable so they can be
/// tested without a router.
class DevicesNavigator {
  /// Callers check `DeviceModelX.isSupported` first.
  void goToDeviceHome(DeviceModel model) => _go(
    model.isPortable ? RoutePaths.portableControl : RoutePaths.volcanoControl,
  );

  void goToDevices() => _go(RoutePaths.devices);

  void goToWelcome() => _go(RoutePaths.welcome);

  /// On top of the current screen, so back returns to it.
  void openDemo() => _router?.push(RoutePaths.demo);

  /// Pops the current screen, or goes to [fallback] when there is nothing to
  /// pop.
  void back({required String fallback}) {
    final router = _router;
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallback);
    }
  }

  void _go(String path) => _router?.go(path);

  GoRouter? get _router {
    final context = rootNavigatorKey.currentContext;
    return context == null ? null : GoRouter.of(context);
  }
}
