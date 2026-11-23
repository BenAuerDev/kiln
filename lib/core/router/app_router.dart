import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'app_routes.dart';
import 'navigator_keys.dart';
import 'route_paths.dart';

/// [refresh] must notify when [pastWelcome] changes. The caller owns it.
/// While [pastWelcome] is false, every route except the welcome and the demo
/// picker leads to the welcome.
GoRouter buildAppRouter({
  required Listenable refresh,
  required ReadonlySignal<bool> pastWelcome,
}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.root,
  refreshListenable: refresh,
  routes: [
    GoRoute(path: RoutePaths.root, redirect: (_, _) => RoutePaths.devices),
    ...appRoutes(),
  ],
  redirect: (context, state) =>
      welcomeGate(state.matchedLocation, pastWelcome: pastWelcome.value),
);

/// Where [location] leads: the welcome until [pastWelcome], except for the
/// welcome itself and the demo picker. `null` keeps the location.
String? welcomeGate(String location, {required bool pastWelcome}) {
  const open = {RoutePaths.welcome, RoutePaths.demo};
  if (pastWelcome || open.contains(location)) return null;
  return RoutePaths.welcome;
}
