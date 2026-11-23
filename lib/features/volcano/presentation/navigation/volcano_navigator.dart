import 'package:go_router/go_router.dart';

import '../../../../core/router/navigator_keys.dart';
import '../../../../core/router/route_paths.dart';

/// Navigation used by the Volcano view model, injectable so it can be tested
/// without a router.
class VolcanoNavigator {
  void goToDevices() => _go(RoutePaths.devices);

  void goToControl() => _go(RoutePaths.volcanoControl);

  void goToWorkflows() => _go(RoutePaths.volcanoWorkflows);

  void _go(String path) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).go(path);
  }
}
