import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/router/app_router.dart';
import 'package:kiln/core/router/route_paths.dart';

void main() {
  group('welcomeGate before the welcome', () {
    test('keeps the welcome and the demo picker open', () {
      for (final location in [RoutePaths.welcome, RoutePaths.demo]) {
        expect(welcomeGate(location, pastWelcome: false), isNull);
      }
    });

    test('sends every other route to the welcome', () {
      for (final location in [
        RoutePaths.devices,
        RoutePaths.portableControl,
        RoutePaths.portableSetup,
        RoutePaths.portableSettings,
        RoutePaths.volcanoControl,
      ]) {
        expect(
          welcomeGate(location, pastWelcome: false),
          RoutePaths.welcome,
          reason: location,
        );
      }
    });
  });

  test('past the welcome, every route stays where it is', () {
    for (final location in [
      RoutePaths.welcome,
      RoutePaths.demo,
      RoutePaths.devices,
      RoutePaths.volcanoControl,
    ]) {
      expect(welcomeGate(location, pastWelcome: true), isNull);
    }
  });
}
