import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/repositories/ramps_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/domain/use_cases/find_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/toggle_ramp_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late RampRunRepository runs;
  late MockStartRampUseCase start;
  late MockStopRampUseCase stop;
  late ToggleRampUseCase toggle;
  late RampsRepository userRamps;

  setUpAll(() => registerFallbackValue(RampService.defaultPreset));

  setUp(() {
    runs = RampRunRepository();
    start = MockStartRampUseCase();
    stop = MockStopRampUseCase();
    when(() => start(any())).thenAnswer((_) async => right(unit));
    when(() => stop()).thenAnswer((_) async => right(unit));
    userRamps = fakeRampsRepository();
    toggle = ToggleRampUseCase(
      runs: runs,
      userRamps: userRamps,
      findRamp: FindRampUseCase(repository: userRamps),
      startRamp: start,
      stopRamp: stop,
    );
  });

  tearDown(() => runs.clear());

  test('starts the chosen ramp', () async {
    await userRamps.select('preset.quick');
    expect(await toggle(), right(unit));
    verify(() => start(RampService.presets[2])).called(1);
    verifyNever(() => stop());
  });

  test('starts Classic when the chosen ramp is gone', () async {
    await userRamps.select('user.deleted');
    await toggle();
    verify(() => start(RampService.defaultPreset)).called(1);
  });

  test('starts again after a finished ramp; passes errors on', () async {
    runs.end(
      RampRun(
        profile: RampService.defaultPreset,
        deviceId: 'v',
        session: 1,
        target: 200,
        nextStepAt: DateTime(2026),
        phase: RampRunPhase.finished,
      ),
    );
    when(
      () => start(any()),
    ).thenAnswer((_) async => left(const AppError.notConnected()));
    expect(await toggle(), left(const AppError.notConnected()));
    verify(() => start(RampService.defaultPreset)).called(1);
  });

  test('stops a running ramp', () async {
    runs.update(
      RampRun(
        profile: RampService.defaultPreset,
        deviceId: 'v',
        session: 1,
        target: 180,
        nextTarget: 185,
        nextStepAt: DateTime(2026),
      ),
    );
    await toggle();
    verify(() => stop()).called(1);
    verifyNever(() => start(any()));
  });
}
