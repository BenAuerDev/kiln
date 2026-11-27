import 'package:go_router/go_router.dart';

import '../../../../core/router/navigator_keys.dart';
import '../../../../core/router/route_paths.dart';

/// Navigation of the ramp view models, injectable so they can be tested
/// without a router.
class RampsNavigator {
  /// Edits the user ramp [id], or starts a new ramp with the values of the
  /// ramp [from] (a preset or user ramp).
  void openEditor({String? id, String? from}) => _router?.push(
    Uri(
      path: RoutePaths.rampEditor,
      queryParameters: {'id': ?id, 'from': ?from},
    ).toString(),
  );

  /// Pops, or goes to the Setup tab when there is nothing to pop.
  void back() {
    final router = _router;
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.portableSetup);
    }
  }

  GoRouter? get _router {
    final context = rootNavigatorKey.currentContext;
    return context == null ? null : GoRouter.of(context);
  }
}
