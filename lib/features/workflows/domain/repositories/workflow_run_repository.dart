import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../models/workflow_run.dart';

/// Holds the workflow that runs or last ran, and the tick that drives it
/// (ARCHITECTURE.md, Addendum 1). The tick calls back into a use case; this
/// repository makes no decisions and does no I/O.
class WorkflowRunRepository {
  WorkflowRunRepository({this._tick = const Duration(milliseconds: 500)});

  final Duration _tick;

  final _run = signal<WorkflowRun?>(null);
  Timer? _ticker;
  bool _ticking = false;
  Future<void> _queue = Future.value();

  /// `null` until a workflow is started, and after [clear].
  ReadonlySignal<WorkflowRun?> get run => _run;

  /// Runs [job] after every job queued before it, so ticks, Start, Skip and
  /// Stop never interleave their writes: a Stop always sends its "off" writes
  /// after a tick that was already under way.
  Future<T> serialized<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  /// Replaces any earlier run and calls [onTick] every tick, through
  /// [serialized], until [end] or [clear]. A tick is skipped while the
  /// previous one is still queued or running.
  void start(WorkflowRun run, Future<void> Function() onTick) {
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

  void update(WorkflowRun run) => _run.value = run;

  /// Stops the tick and keeps [run] (finished or stopped) for the UI.
  void end(WorkflowRun run) {
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
