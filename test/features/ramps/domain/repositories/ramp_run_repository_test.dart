import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';

void main() {
  final run = RampRun(
    profile: RampService.presets.first,
    deviceId: 'v',
    session: 1,
    target: 170,
    nextStepAt: DateTime(2026),
  );

  test('ticks every second until end, and keeps the ended run', () {
    fakeAsync((async) {
      final repository = RampRunRepository();
      var ticks = 0;
      repository.start(run, () async => ticks++);
      async.elapse(const Duration(seconds: 3));
      expect(ticks, 3);
      repository.end(run.copyWith(phase: RampRunPhase.finished));
      async.elapse(const Duration(seconds: 3));
      expect(ticks, 3);
      expect(repository.run.value!.phase, RampRunPhase.finished);
      repository.clear();
      expect(repository.run.value, isNull);
    });
  });

  test('a slow tick is not overlapped; serialized jobs run in order', () {
    fakeAsync((async) {
      final repository = RampRunRepository();
      final slow = Completer<void>();
      final order = <String>[];
      var ticks = 0;
      repository.start(run, () {
        ticks++;
        order.add('tick');
        return slow.future;
      });
      async.elapse(const Duration(seconds: 1));
      repository.serialized(() async => order.add('stop'));
      async.elapse(const Duration(seconds: 3));
      expect(ticks, 1);
      expect(order, ['tick']);
      slow.complete();
      async.flushMicrotasks();
      expect(order, ['tick', 'stop']);
      repository.clear();
    });
  });

  test('a failing job does not block the queue', () async {
    final repository = RampRunRepository();
    await expectLater(
      repository.serialized<void>(() async => throw StateError('x')),
      throwsStateError,
    );
    expect(await repository.serialized(() async => 42), 42);
  });

  test('select keeps the chosen preset', () {
    final repository = RampRunRepository();
    expect(repository.selected.value, RampService.presets[1]);
    repository.select(RampService.presets[2]);
    expect(repository.selected.value, RampService.presets[2]);
  });
}
