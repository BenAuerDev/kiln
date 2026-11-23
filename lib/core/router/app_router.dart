import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_settings/domain/repositories/app_settings_repository.dart';
import '../service_locator.dart';
import 'app_routes.dart';
import 'navigator_keys.dart';
import 'route_paths.dart';

/// [refresh] must notify when `welcomeCompleted` changes. The caller owns it.
GoRouter buildAppRouter({required Listenable refresh}) {
  final settings = sl<AppSettingsRepository>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.root,
    refreshListenable: refresh,
    routes: [
      GoRoute(path: RoutePaths.root, redirect: (_, _) => RoutePaths.devices),
      ...appRoutes(),
    ],
    redirect: (context, state) {
      final onWelcome = state.matchedLocation == RoutePaths.welcome;
      if (!settings.welcomeCompleted.value && !onWelcome) {
        return RoutePaths.welcome;
      }
      return null;
    },
  );
}
