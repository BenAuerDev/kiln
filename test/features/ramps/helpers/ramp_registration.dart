import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/repositories/ramps_repository.dart';
import 'package:kiln/features/ramps/domain/use_cases/find_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/load_ramps_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/select_ramp_use_case.dart';
import 'package:kiln/features/ramps/presentation/navigation/ramps_navigator.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/presentation/view_models/ramp_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../mocks.dart';

/// Registers the view model of the ramp card and banner on the portable
/// screens; no ramp runs unless [runs] holds one.
void registerRamp({
  RampRunRepository? runs,
  PortableStatus? status,
  RampsRepository? ramps,
  RampsNavigator? navigator,
}) {
  final userRamps = ramps ?? fakeRampsRepository();
  final haptics = MockHapticsService();
  when(() => haptics.tick()).thenAnswer((_) async {});
  when(() => haptics.success()).thenAnswer((_) async {});
  when(() => haptics.warning()).thenAnswer((_) async {});
  final portable = MockPortableRepository();
  when(() => portable.status).thenReturn(signal(status));
  when(() => portable.sessionActive).thenReturn(signal(status != null));
  when(() => portable.sessionNumber).thenReturn(signal(1));
  final connection = MockConnectionRepository();
  when(() => connection.activeDeviceId).thenReturn(signal('veazy-id'));
  sl.registerFactory(
    () => RampViewModel(
      runs: runs ?? RampRunRepository(),
      userRamps: userRamps,
      findRamp: FindRampUseCase(repository: userRamps),
      loadRamps: LoadRampsUseCase(repository: userRamps),
      selectRamp: SelectRampUseCase(repository: userRamps),
      navigator: navigator ?? MockRampsNavigator(),
      portable: portable,
      connection: connection,
      ramps: const RampService(),
      startRamp: MockStartRampUseCase(),
      stopRamp: MockStopRampUseCase(),
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: MockToastService(),
      refresh: const Duration(hours: 1),
    ),
  );
}
