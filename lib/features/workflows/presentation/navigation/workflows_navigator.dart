import 'package:go_router/go_router.dart';

import '../../../../core/router/navigator_keys.dart';
import '../../../../core/router/route_paths.dart';

/// Navigation used by the workflow view models, injectable so they can be
/// tested without a router.
class WorkflowsNavigator {
  void goToWorkflows() => _router?.go(RoutePaths.volcanoWorkflows);

  /// On top of the list, so back returns to it.
  void openRun() => _router?.push(RoutePaths.workflowRun);

  /// [id]: a user workflow to edit or a preset to copy; `null` for a new one.
  void openEditor({String? id}) => _router?.push(
    Uri(
      path: RoutePaths.workflowEditor,
      queryParameters: id == null ? null : {'id': id},
    ).toString(),
  );

  /// Pops, or goes to the workflow list when there is nothing to pop.
  void back() {
    final router = _router;
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.volcanoWorkflows);
    }
  }

  GoRouter? get _router {
    final context = rootNavigatorKey.currentContext;
    return context == null ? null : GoRouter.of(context);
  }
}
