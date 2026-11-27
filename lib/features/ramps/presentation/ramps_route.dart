import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import 'screens/ramp_editor_screen.dart';

class RampEditorRoute extends GoRoute {
  RampEditorRoute()
    : super(
        path: RoutePaths.rampEditor,
        builder: (_, state) => RampEditorScreen(
          rampId: state.uri.queryParameters['id'],
          fromId: state.uri.queryParameters['from'],
        ),
      );
}

List<RouteBase> rampsRoutes() => [RampEditorRoute()];
