import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../models/ramp_run.dart';

/// Holds the ramp that runs or last ran and the tick
/// that drives a run (ARCHITECTURE.md, Addendum 1). The tick calls back into
/// a use case; this repository makes no decisions and does no I/O.
class RampRunRepository {
  RampRunRepository({this._tick = const Duration(seconds: 1)});

  final Duration _tick;

  final _run = signal<RampRun?>(null);
  Timer? _ticker;
  bool _ticking = false;
  Future<void> _queue = Future.value();

  ReadonlySignal<RampRun?> get run => _run;

  /// Runs [job] after every job queued before it, so ticks, Start and Stop
  /// never interleave their writes.
  Future<T> serialized<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  /// Replaces any earlier run and calls [onTick] every tick, through
  /// [serialized], until [end].
  void start(RampRun run, Future<void> Function() onTick) {
    _ticker?.cancel();
    _run.value = run;
    _ticker = Timer.periodic(_tick, (_) async {
      if (_ticking) return;
      _ticking = true;
      try {
        await serialized(onTick);
      } finally {
        _ticking = false;
      }
    });
  }

  void update(RampRun run) => _run.value = run;

  /// Stops the tick and keeps [run] (finished or stopped) for the UI.
  void end(RampRun run) {
    _ticker?.cancel();
    _ticker = null;
    _run.value = run;
  }

  void clear() {
    _ticker?.cancel();
    _ticker = null;
    _run.value = null;
  }
}
