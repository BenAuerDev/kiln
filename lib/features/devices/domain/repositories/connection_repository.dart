import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/ble/ble_connection_state.dart';
import '../../../../core/ble/ble_error_mapper.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/device_connection_data_source.dart';
import '../models/connection_status.dart';

/// Owns the single active BLE connection, its status and the auto-reconnect
/// job.
///
/// Every connect, reconnect or disconnect starts a new generation. A job that
/// finds a newer generation stops without touching the signals, so a late
/// result never overwrites the current state.
class ConnectionRepository {
  ConnectionRepository({
    DeviceConnectionDataSource? dataSource,
    this._retryDelays = defaultRetryDelays,
    this._now = DateTime.now,
  }) : _dataSource = dataSource ?? sl<DeviceConnectionDataSource>();

  /// A connection that drops sooner than this counts as a short drop. A
  /// switched-off Venty hangs up 15–30 s after each reconnect.
  static const stableAfter = Duration(seconds: 60);

  /// Short drops in a row after which auto-reconnect gives up. A Venty that
  /// was switched off accepts a connection, vibrates and drops it again a
  /// moment later; reconnecting forever would keep it awake and buzzing.
  static const maxShortDrops = 2;

  /// Wait before each reconnect attempt. The first attempt of a reconnect
  /// requested on app start or resume does not wait.
  static const defaultRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  final DeviceConnectionDataSource _dataSource;
  final List<Duration> _retryDelays;
  final DateTime Function() _now;

  final _activeDeviceId = signal<String?>(null);
  final _status = signal<ConnectionStatus>(ConnectionStatus.disconnected);
  final _disconnectedByUser = signal<bool>(false);

  StreamSubscription<BleConnectionState>? _stateSubscription;
  Future<Either<AppError, Unit>>? _reconnectJob;
  int _generation = 0;
  DateTime? _connectedAt;
  int _shortDrops = 0;
  bool _reconnectAfterDrop = true;

  /// Stays set after a failed connect or an exhausted reconnect, so the UI
  /// can still name the device. Cleared by [disconnect].
  ReadonlySignal<String?> get activeDeviceId => _activeDeviceId;
  ReadonlySignal<ConnectionStatus> get status => _status;

  /// True after an explicit [disconnect] until the next connect, so resuming
  /// the app does not undo the user's choice.
  ReadonlySignal<bool> get disconnectedByUser => _disconnectedByUser;

  /// Called with the active device id before kiln lets go of it (disconnect,
  /// forget, or connecting to another device), while it can still be
  /// written to: a running Volcano workflow switches pump and heater off
  /// here. Errors are the callback's own business.
  Future<void> Function(String deviceId)? beforeRelease;

  /// Whether an unexpected drop of the current connection should be
  /// reconnected. Device features turn it off while the device is idle, so
  /// a device that hangs up to go to sleep is left alone. Every explicit
  /// [connect] or [reconnect] turns it back on.
  void setReconnectAfterDrop(bool value) => _reconnectAfterDrop = value;

  Future<Either<AppError, Unit>> connect(String deviceId) async {
    _shortDrops = 0;
    _reconnectAfterDrop = true;
    if (_activeDeviceId.value == deviceId &&
        _status.value == ConnectionStatus.connected) {
      return right(unit);
    }
    if (_hasOtherActive(deviceId)) await disconnect();
    final generation = _begin(deviceId, ConnectionStatus.connecting);
    try {
      await _dataSource.connect(deviceId);
    } catch (e) {
      if (generation != _generation) {
        return left(const AppError.connectionFailed());
      }
      _status.value = ConnectionStatus.unavailable;
      return left(BleErrorMapper.toAppError(e));
    }
    if (generation != _generation) {
      _dropIfStale(deviceId);
      return left(const AppError.connectionFailed());
    }
    _onConnected(deviceId, generation);
    return right(unit);
  }

  /// Runs the auto-reconnect job for [deviceId]: up to one attempt per entry
  /// of the retry delays, then [ConnectionStatus.disconnected]. Joins a job
  /// that is already running for the same device.
  Future<Either<AppError, Unit>> reconnect(String deviceId) async {
    _shortDrops = 0;
    _reconnectAfterDrop = true;
    final sameDevice = _activeDeviceId.value == deviceId;
    if (sameDevice && _status.value == ConnectionStatus.connected) {
      return right(unit);
    }
    final running = _reconnectJob;
    if (sameDevice && running != null) return running;
    if (_hasOtherActive(deviceId)) await disconnect();
    return _startReconnect(deviceId, afterDrop: false);
  }

  /// [byUser]: an explicit disconnect that keeps auto-reconnect off until
  /// the next connect. Leaving the demo passes `false`, so the last real
  /// device comes back on the next resume.
  Future<Either<AppError, Unit>> disconnect({bool byUser = true}) async {
    final current = _activeDeviceId.value;
    final hook = beforeRelease;
    if (current != null &&
        hook != null &&
        _status.value == ConnectionStatus.connected) {
      await hook(current);
    }
    // Read again: a connect may have replaced the device during the hook.
    final id = _activeDeviceId.value;
    _generation++;
    _reconnectJob = null;
    _activeDeviceId.value = null;
    _status.value = ConnectionStatus.disconnected;
    _disconnectedByUser.value = byUser;
    await _cancelStateSubscription();
    if (id == null) return right(unit);
    try {
      await _dataSource.disconnect(id);
      return right(unit);
    } catch (e) {
      return left(BleErrorMapper.toAppError(e));
    }
  }

  int _begin(String deviceId, ConnectionStatus status) {
    _generation++;
    _reconnectJob = null;
    unawaited(_cancelStateSubscription());
    _activeDeviceId.value = deviceId;
    _status.value = status;
    _disconnectedByUser.value = false;
    return _generation;
  }

  Future<Either<AppError, Unit>> _startReconnect(
    String deviceId, {
    required bool afterDrop,
  }) {
    final generation = _begin(deviceId, ConnectionStatus.reconnecting);
    final job = _runReconnect(deviceId, generation, afterDrop: afterDrop);
    _reconnectJob = job;
    return job;
  }

  Future<Either<AppError, Unit>> _runReconnect(
    String deviceId,
    int generation, {
    required bool afterDrop,
  }) async {
    AppError lastError = const AppError.connectionFailed();
    for (var attempt = 0; attempt < _retryDelays.length; attempt++) {
      if (attempt > 0 || afterDrop) {
        await Future<void>.delayed(_retryDelays[attempt]);
      }
      if (generation != _generation) return left(lastError);
      try {
        await _dataSource.connect(deviceId);
      } catch (e) {
        lastError = BleErrorMapper.toAppError(e);
        if (generation != _generation) return left(lastError);
        if (lastError is PermissionDeniedError) break;
        continue;
      }
      if (generation != _generation) {
        _dropIfStale(deviceId);
        return left(lastError);
      }
      _reconnectJob = null;
      _onConnected(deviceId, generation);
      return right(unit);
    }
    if (generation == _generation) {
      _reconnectJob = null;
      _status.value = ConnectionStatus.disconnected;
    }
    return left(lastError);
  }

  void _onConnected(String deviceId, int generation) {
    _status.value = ConnectionStatus.connected;
    _connectedAt = _now();
    _stateSubscription = _dataSource.connectionState(deviceId).listen((state) {
      if (generation != _generation ||
          state != BleConnectionState.disconnected ||
          _status.value != ConnectionStatus.connected) {
        return;
      }
      _onUnexpectedDrop(deviceId);
    }, onError: (Object _) {});
  }

  void _onUnexpectedDrop(String deviceId) {
    final connectedAt = _connectedAt;
    final short =
        connectedAt != null && _now().difference(connectedAt) < stableAfter;
    _shortDrops = short ? _shortDrops + 1 : 0;
    if (!_reconnectAfterDrop || _shortDrops >= maxShortDrops) {
      // Idle, or the device keeps hanging up: let it sleep. Opening the app
      // or tapping the device tries again.
      _generation++;
      _reconnectJob = null;
      unawaited(_cancelStateSubscription());
      _status.value = ConnectionStatus.disconnected;
      return;
    }
    unawaited(_startReconnect(deviceId, afterDrop: true));
  }

  bool _hasOtherActive(String deviceId) {
    final current = _activeDeviceId.value;
    return current != null && current != deviceId;
  }

  /// A superseded job connected after all: let go of the link unless the
  /// device became active again in the meantime.
  void _dropIfStale(String deviceId) {
    if (_activeDeviceId.value == deviceId) return;
    unawaited(
      _dataSource.disconnect(deviceId).then((_) {}, onError: (Object _) {}),
    );
  }

  Future<void> _cancelStateSubscription() async {
    final subscription = _stateSubscription;
    _stateSubscription = null;
    await subscription?.cancel();
  }
}
