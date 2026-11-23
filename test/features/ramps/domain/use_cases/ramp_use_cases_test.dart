import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/domain/use_cases/advance_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/start_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/stop_ramp_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../portable/helpers/portable_fixtures.dart' show testStatus;
import '../../mocks.dart';

void main() {
  late MockPortableRepository portable;
  late Signal<PortableStatus?> status;
  late Signal<String?> activeId;
  late Signal<int> session;
  late RampRunRepository runs;
  late DateTime now;
  late AdvanceRampUseCase advance;
  late StartRampUseCase start;

  final t0 = DateTime(2026, 11, 23, 21);
  final classic = RampService.presets[1]; // 180→200, +5 every 90 s

  setUpAll(() => registerFallbackValue(HeaterMode.off));

  setUp(() {
    portable = MockPortableRepository();
    status = signal(testStatus(target: 185, heaterMode: HeaterMode.off));
    when(() => portable.status).thenReturn(status);
    // Fresh unless a test says otherwise.
    when(() => portable.statusUpdatedAt).thenAnswer((_) => signal(now));
    session = signal(1);
    when(() => portable.sessionNumber).thenReturn(session);
    when(() => portable.setTargetTemperature(any())).thenAnswer((call) async {
      final target = call.positionalArguments.first as int;
      status.value = status.value!.copyWith(targetTemperature: target);
      return right(unit);
    });
    when(() => portable.setHeaterMode(any())).thenAnswer((call) async {
      final mode = call.positionalArguments.first as HeaterMode;
      status.value = status.value!.copyWith(heaterMode: mode);
      return right(unit);
    });
    activeId = signal('veazy-id');
    final connection = MockConnectionRepository();
    when(() => connection.activeDeviceId).thenReturn(activeId);
    runs = RampRunRepository(tick: const Duration(hours: 1));
    now = t0;
    advance = AdvanceRampUseCase(
      runs: runs,
      portable: portable,
      connection: connection,
      ramps: RampService(),
      clock: () => now,
    );
    start = StartRampUseCase(
      runs: runs,
      portable: portable,
      connection: connection,
      ramps: RampService(),
      advance: advance,
      clock: () => now,
    );
  });

  tearDown(() => runs.clear());

  RampRun run() => runs.run.value!;

  group('start', () {
    test('sets the first temperature and turns the heater on', () async {
      expect(await start(classic), right<AppError, Unit>(unit));
      verifyInOrder([
        () => portable.setTargetTemperature(180),
        () => portable.setHeaterMode(HeaterMode.normal),
      ]);
      expect(run().target, 180);
      expect(run().nextTarget, 185);
      expect(run().deviceId, 'veazy-id');
      expect(run().session, 1);
      expect(run().nextStepAt, t0.add(const Duration(seconds: 90)));
    });

    test('writes nothing the device already has', () async {
      status.value = testStatus(target: 180, heaterMode: HeaterMode.normal);
      await start(classic);
      verifyNever(() => portable.setTargetTemperature(any()));
      verifyNever(() => portable.setHeaterMode(any()));
    });

    test('not while boosting, not without a device', () async {
      status.value = testStatus(heaterMode: HeaterMode.boost);
      expect(
        (await start(classic)).getLeft().toNullable(),
        isA<WriteNotVerifiedError>(),
      );
      status.value = null;
      expect(
        (await start(classic)).getLeft().toNullable(),
        isA<NotConnectedError>(),
      );
      expect(runs.run.value, isNull);
    });
  });

  group('advance', () {
    setUp(() async => start(classic));

    test('waits until a step is due, then writes it', () async {
      now = t0.add(const Duration(seconds: 60));
      await advance();
      verifyNever(() => portable.setTargetTemperature(185));
      now = t0.add(const Duration(seconds: 90));
      await advance();
      verify(() => portable.setTargetTemperature(185)).called(1);
      expect(run().target, 185);
      expect(run().nextTarget, 190);
      expect(run().nextStepAt, now.add(const Duration(seconds: 90)));
    });

    test('finishes on the last step and keeps the heater on', () async {
      for (var i = 1; i <= 4; i++) {
        now = t0.add(Duration(seconds: 90 * i));
        await advance();
      }
      expect(run().phase, RampRunPhase.finished);
      expect(run().target, 200);
      expect(run().nextTarget, isNull);
      verifyNever(() => portable.setHeaterMode(HeaterMode.off));
    });

    test('a due step waits for boost to end', () async {
      status.value = status.value!.copyWith(heaterMode: HeaterMode.boost);
      now = t0.add(const Duration(seconds: 100));
      await advance();
      expect(run().waitingForBoost, isTrue);
      verifyNever(() => portable.setTargetTemperature(185));

      status.value = status.value!.copyWith(heaterMode: HeaterMode.normal);
      await advance();
      verify(() => portable.setTargetTemperature(185)).called(1);
      expect(run().waitingForBoost, isFalse);
    });

    test('a stale status (polling paused) writes nothing and waits', () async {
      now = t0.add(const Duration(seconds: 90));
      when(
        () => portable.statusUpdatedAt,
      ).thenAnswer((_) => signal(now.subtract(const Duration(seconds: 3))));
      await advance();
      verifyNever(() => portable.setTargetTemperature(185));
      expect(run().phase, RampRunPhase.running);

      when(() => portable.statusUpdatedAt).thenAnswer((_) => signal(now));
      await advance();
      verify(() => portable.setTargetTemperature(185)).called(1);
    });

    test('stale for over two minutes ends the ramp', () async {
      final lastUpdate = t0;
      when(
        () => portable.statusUpdatedAt,
      ).thenAnswer((_) => signal(lastUpdate));
      now = t0.add(const Duration(minutes: 1));
      await advance();
      expect(run().phase, RampRunPhase.running);
      now = t0.add(const Duration(minutes: 2, seconds: 1));
      await advance();
      expect(run().phase, RampRunPhase.stopped);
      verifyNever(() => portable.setTargetTemperature(185));
    });

    test('a new session on the same device ends the ramp', () async {
      session.value = 2;
      await advance();
      expect(run().phase, RampRunPhase.stopped);
    });

    test('a short heater off (ending boost) does not stop it', () async {
      status.value = status.value!.copyWith(heaterMode: HeaterMode.off);
      await advance();
      now = t0.add(const Duration(seconds: 2));
      await advance();
      expect(run().phase, RampRunPhase.running);
      status.value = status.value!.copyWith(heaterMode: HeaterMode.normal);
      await advance();
      expect(run().heaterOffSince, isNull);
      expect(run().phase, RampRunPhase.running);
    });

    test('a failed write that reached the device is adopted', () async {
      when(
        () => portable.setTargetTemperature(185),
      ).thenAnswer((_) async => left(const AppError.timeout()));
      now = t0.add(const Duration(seconds: 90));
      await advance();
      expect(run().pendingTarget, 185);
      status.value = status.value!.copyWith(targetTemperature: 185);
      await advance();
      expect(run().phase, RampRunPhase.running);
      expect(run().target, 185);
      expect(run().pendingTarget, isNull);
    });

    test(
      'a late step is rescheduled from now, an on-time one is not',
      () async {
        now = t0.add(const Duration(seconds: 91));
        await advance();
        expect(run().nextStepAt, t0.add(const Duration(seconds: 180)));
        now = t0.add(const Duration(seconds: 400));
        await advance();
        expect(run().nextStepAt, now.add(const Duration(seconds: 90)));
      },
    );

    test('a manual base change stops the ramp', () async {
      status.value = status.value!.copyWith(targetTemperature: 195);
      await advance();
      expect(run().phase, RampRunPhase.stopped);
    });

    test('heater off, another device or no session stop it', () async {
      status.value = status.value!.copyWith(heaterMode: HeaterMode.off);
      await advance();
      now = t0.add(const Duration(seconds: 3));
      await advance();
      expect(run().phase, RampRunPhase.stopped);
      now = t0;

      await start(classic);
      activeId.value = 'venty-id';
      await advance();
      expect(run().phase, RampRunPhase.stopped);

      activeId.value = 'veazy-id';
      await start(classic);
      status.value = null;
      await advance();
      expect(run().phase, RampRunPhase.stopped);
    });

    test('a failed write keeps the step for the next tick', () async {
      when(
        () => portable.setTargetTemperature(185),
      ).thenAnswer((_) async => left(const AppError.timeout()));
      now = t0.add(const Duration(seconds: 90));
      expect((await advance()).isLeft(), isTrue);
      expect(run().target, 180);
      expect(run().phase, RampRunPhase.running);
    });
  });

  test('stop ends the ramp without writing', () async {
    await start(classic);
    clearInteractions(portable);
    await StopRampUseCase(runs: runs)();
    expect(run().phase, RampRunPhase.stopped);
    verifyNever(() => portable.setTargetTemperature(any()));
    verifyNever(() => portable.setHeaterMode(any()));
  });
}
