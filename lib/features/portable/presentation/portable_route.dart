import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import 'screens/portable_control_screen.dart';
import 'screens/portable_settings_screen.dart';
import 'screens/portable_setup_screen.dart';

class PortableControlRoute extends GoRoute {
  PortableControlRoute()
    : super(
        path: RoutePaths.portableControl,
        builder: (_, _) => const PortableControlScreen(),
      );
}

class PortableSetupRoute extends GoRoute {
  PortableSetupRoute()
    : super(
        path: RoutePaths.portableSetup,
        builder: (_, _) => const PortableSetupScreen(),
      );
}

class PortableSettingsRoute extends GoRoute {
  PortableSettingsRoute()
    : super(
        path: RoutePaths.portableSettings,
        builder: (_, _) => const PortableSettingsScreen(),
      );
}

List<RouteBase> portableRoutes() => [
  PortableControlRoute(),
  PortableSetupRoute(),
  PortableSettingsRoute(),
];
