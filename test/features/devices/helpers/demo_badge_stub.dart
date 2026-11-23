import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/presentation/view_models/demo_badge_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'mocks.dart';

/// Registers the view model of the `DemoBadge` that device headers show.
/// [activeDevice] decides whether it is visible (only for a demo device).
void registerDemoBadge({KnownDevice? activeDevice}) {
  final knownDevices = MockKnownDevicesRepository();
  when(() => knownDevices.activeDevice).thenReturn(signal(activeDevice));
  sl.registerFactory(
    () => DemoBadgeViewModel(
      knownDevices: knownDevices,
      settings: MockAppSettingsRepository(),
      leaveDemo: MockLeaveDemoUseCase(),
      l10n: FakeL10nService(),
      haptics: MockHapticsService(),
      toast: MockToastService(),
      navigator: MockDevicesNavigator(),
    ),
  );
}
