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

  void _go(String path) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).go(path);
  }
}
