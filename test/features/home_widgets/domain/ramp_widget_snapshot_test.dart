import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/home_widgets/domain/models/ramp_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/domain/services/home_widget_snapshot_service.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/ramps/domain/models/ramp_profile.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';

import '../../portable/helpers/portable_fixtures.dart' show testStatus;
import '../mocks.dart';

void main() {
  final service = HomeWidgetSnapshotService(PortableLadderService());
  final classic = RampService.defaultPreset;
  final due = DateTime(2026, 11, 27, 21);
  const evening = RampProfile(
    id: 'user.1',
    name: 'Evening',
    startCelsius: 175,
    endCelsius: 195,
    stepCelsius: 5,
    interval: Duration(minutes: 1),
  );

  RampRun run({
    int target = 185,
    int? next = 190,
    RampRunPhase phase = RampRunPhase.running,
    bool waitingForBoost = false,
    int? pendingTarget,
    String deviceId = 'vz',
    int session = 1,
  }) => RampRun(
    profile: classic,
    deviceId: deviceId,
    session: session,
    target: target,
    nextTarget: next,
    nextStepAt: due,
    phase: phase,
    waitingForBoost: waitingForBoost,
    pendingTarget: pendingTarget,
  );

  RampWidgetSnapshot? snapshot({
    RampRun? ramp,
    RampProfile? chosen,
    int base = 185,
    HeaterMode heaterMode = HeaterMode.normal,
  }) => service.ramp(
    device: veazy,
    connection: ConnectionStatus.connected,
    status: testStatus(target: base, heaterMode: heaterMode),
    session: 1,
    run: ramp,
    chosen: chosen,
  );

  test('idle: the chosen ramp from its start, or Classic', () {
    final idle = snapshot(chosen: evening)!;
    expect(idle.phase, RampWidgetPhase.idle);
    expect(idle.profile, evening);
    expect([idle.target, idle.step, idle.steps], [175, 0, 4]);
    expect(idle.duration, const Duration(minutes: 4));
    expect(idle.nextStepAt, isNull);
    expect(idle.finish, DeviceFinish.blue);
    expect(snapshot()!.profile, classic);
  });

  test('running: the step reached, the next one and when it is due', () {
    final running = snapshot(ramp: run(), chosen: evening)!;
    expect(running.phase, RampWidgetPhase.running);
    expect(running.profile, classic);
    expect([running.target, running.step, running.steps], [185, 1, 4]);
    expect(running.nextTarget, 190);
    expect(running.nextStepAt, due);
    expect(running.isRunning, isTrue);
  });

  test('idle while boosting says so', () {
    expect(snapshot()!.boosting, isFalse);
    expect(snapshot(heaterMode: HeaterMode.boost)!.boosting, isTrue);
  });

  test('a failed step write: no countdown while it is retried', () {
    final failing = snapshot(ramp: run(pendingTarget: 190))!;
    expect(failing.phase, RampWidgetPhase.running);
    expect(failing.nextStepAt, isNull);
  });

  test('waiting for boost: no countdown', () {
    final waiting = snapshot(ramp: run(waitingForBoost: true))!;
    expect(waiting.phase, RampWidgetPhase.waitingForBoost);
    expect(waiting.nextTarget, 190);
    expect(waiting.nextStepAt, isNull);
  });

  test('finished while the base stays at the end', () {
    final done = run(target: 200, next: null, phase: RampRunPhase.finished);
    final finished = snapshot(ramp: done, base: 200)!;
    expect(finished.phase, RampWidgetPhase.finished);
    expect(finished.step, finished.steps);
    expect(finished.isRunning, isFalse);
    // The base was changed by hand since: back to the chosen ramp.
    expect(snapshot(ramp: done, base: 190)!.phase, RampWidgetPhase.idle);
  });

  test('a stopped run, another device or session shows the chosen ramp', () {
    for (final ramp in [
      run(phase: RampRunPhase.stopped),
      run(deviceId: 'other'),
      run(session: 2),
    ]) {
      expect(snapshot(ramp: ramp)!.phase, RampWidgetPhase.idle);
    }
  });

  test('nothing for a demo, a Volcano, no link or no status', () {
    RampWidgetSnapshot? on(
      KnownDevice? device,
      ConnectionStatus link,
      bool hasStatus,
    ) => service.ramp(
      device: device,
      connection: link,
      status: hasStatus ? testStatus() : null,
      session: 1,
      run: null,
      chosen: null,
    );
    expect(on(demoVeazy, ConnectionStatus.connected, true), isNull);
    expect(on(volcanoDevice, ConnectionStatus.connected, true), isNull);
    expect(on(null, ConnectionStatus.connected, true), isNull);
    expect(on(veazy, ConnectionStatus.disconnected, true), isNull);
    expect(on(veazy, ConnectionStatus.connected, false), isNull);
  });
}
