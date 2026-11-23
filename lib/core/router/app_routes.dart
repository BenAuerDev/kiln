import 'package:go_router/go_router.dart';

import '../../features/devices/presentation/devices_route.dart';
import '../../features/portable/presentation/portable_route.dart';
import '../../features/volcano/presentation/volcano_route.dart';

List<RouteBase> appRoutes() => [
  ...devicesRoutes(),
  ...portableRoutes(),
  ...volcanoRoutes(),
];
