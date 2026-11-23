import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import 'screens/workflow_editor_screen.dart';
import 'screens/workflow_run_screen.dart';
import 'screens/workflows_screen.dart';

class WorkflowsRoute extends GoRoute {
  WorkflowsRoute()
    : super(
        path: RoutePaths.volcanoWorkflows,
        builder: (_, _) => const WorkflowsScreen(),
      );
}

class WorkflowRunRoute extends GoRoute {
  WorkflowRunRoute()
    : super(
        path: RoutePaths.workflowRun,
        builder: (_, _) => const WorkflowRunScreen(),
      );
}

class WorkflowEditorRoute extends GoRoute {
  WorkflowEditorRoute()
    : super(
        path: RoutePaths.workflowEditor,
        builder: (_, state) =>
            WorkflowEditorScreen(workflowId: state.uri.queryParameters['id']),
      );
}

List<RouteBase> workflowsRoutes() => [
  WorkflowsRoute(),
  WorkflowRunRoute(),
  WorkflowEditorRoute(),
];
