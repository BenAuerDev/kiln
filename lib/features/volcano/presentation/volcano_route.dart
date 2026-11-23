import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import 'screens/volcano_control_screen.dart';

class VolcanoControlRoute extends GoRoute {
  VolcanoControlRoute()
    : super(
        path: RoutePaths.volcanoControl,
        builder: (_, _) => const VolcanoControlScreen(),
      );
}

List<RouteBase> volcanoRoutes() => [VolcanoControlRoute()];
