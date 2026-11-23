import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import 'screens/demo_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/welcome_screen.dart';

class WelcomeRoute extends GoRoute {
  WelcomeRoute()
    : super(path: RoutePaths.welcome, builder: (_, _) => const WelcomeScreen());
}

class DevicesRoute extends GoRoute {
  DevicesRoute()
    : super(path: RoutePaths.devices, builder: (_, _) => const DevicesScreen());
}

class DemoRoute extends GoRoute {
  DemoRoute()
    : super(path: RoutePaths.demo, builder: (_, _) => const DemoScreen());
}

List<RouteBase> devicesRoutes() => [
  WelcomeRoute(),
  DevicesRoute(),
  DemoRoute(),
];
