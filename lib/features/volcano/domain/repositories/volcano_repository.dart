import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/ble/ble_connection_state.dart';
import '../../../../core/ble/ble_error_mapper.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/volcano_ble_data_source.dart';
import '../../data/models/volcano_write_safety.dart';
import '../models/volcano_status.dart';

/// Live session with one Volcano Hybrid: initial reads, notifications and
/// optimistic writes.
class VolcanoRepository {
  VolcanoRepository({VolcanoBleDataSource? dataSource})
    : _dataSource = dataSource ?? sl<VolcanoBleDataSource>();

  final VolcanoBleDataSource _dataSource;

  final _status = signal<VolcanoStatus?>(null);
  final _sessionActive = signal<bool>(false);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _deviceId;
  int _generation = 0;
  Future<Either<AppError, Unit>>? _pending;
  String? _pendingDeviceId;

  ReadonlySignal<VolcanoStatus?> get status => _status;
  ReadonlySignal<bool> get sessionActive => _sessionActive;

  final _startFailed = signal<bool>(false);

  /// The last session start failed (and was not superseded): the device is
  /// connected but reports nothing. Reset by the next start.
  ReadonlySignal<bool> get startFailed => _startFailed;

  Future<Either<AppError, Unit>> startSession(String deviceId) {
    if (_sessionActive.value && _deviceId == deviceId) {
      return Future.value(right(unit));
    }
    final pending = _pending;
    if (pending != null && _pendingDeviceId == deviceId) return pending;
    final generation = ++_generation;
    _startFailed.value = false;
    final future = _start(deviceId, generation);
    _pending = future;
    _pendingDeviceId = deviceId;
    unawaited(
      future.whenComplete(() {
        if (_generation == generation) {
          _pending = null;
          _pendingDeviceId = null;
        }
      }),
    );
    return future;
  }

  Future<Either<AppError, Unit>> stopSession() async {
    _generation++;
    _pending = null;
    _pendingDeviceId = null;
    await _teardown();
    return right(unit);
  }

  Future<Either<AppError, Unit>> setTargetTemperature(int celsius) => _write(
    (status) => status.copyWith(targetTemperature: celsius),
    (deviceId) => _dataSource.writeTargetTemperature(deviceId, celsius),
  );

  Future<Either<AppError, Unit>> setHeater(bool on) => _write(
    (status) => status.copyWith(heaterOn: on),
    (deviceId) => _dataSource.writeHeater(deviceId, on: on),
  );

  Future<Either<AppError, Unit>> setPump(bool on) => _write(
    (status) => status.copyWith(pumpOn: on),
    (deviceId) => _dataSource.writePump(deviceId, on: on),
  );

  Future<Either<AppError, Unit>> _start(String deviceId, int generation) async {
    await _teardown();
    try {
      final current = await _dataSource.readCurrentTemperature(deviceId);
      final target = await _dataSource.readTargetTemperature(deviceId);
      final register1 = await _dataSource.readRegister1(deviceId);
      final register2 = await _dataSource.readRegister2(deviceId);
      final register3 = await _dataSource.readRegister3(deviceId);
      if (target == null) {
        throw const FormatException('target temperature unavailable');
      }
      if (generation != _generation) return left(const AppError.notConnected());
      _status.value = VolcanoStatus(
        currentTemperature: current,
        targetTemperature: target.round(),
        heaterOn: register1.heaterOn,
        pumpOn: register1.pumpOn,
        autoShutdown: register1.autoShutdown,
        fahrenheit: register2.fahrenheit,
        displayOnCooling: register2.displayOnCooling,
        vibrationWhenReady: register3.vibrationWhenReady,
      );
      _deviceId = deviceId;
      _subscribe(deviceId);
      _sessionActive.value = true;
      return right(unit);
    } catch (e) {
      if (generation == _generation) {
        await _teardown();
        _startFailed.value = true;
      }
      return left(BleErrorMapper.toAppError(e));
    }
  }

  void _subscribe(String deviceId) {
    // A failed notification keeps the last known value; the next session
    // start reads everything again.
    void ignore(Object _) {}
    _subscriptions.addAll([
      _dataSource.connectionState(deviceId).listen((state) {
        if (state == BleConnectionState.disconnected && _deviceId == deviceId) {
          unawaited(stopSession());
        }
      }, onError: ignore),
      _dataSource.watchCurrentTemperature(deviceId).listen((celsius) {
        if (celsius != null) {
          _update((s) => s.copyWith(currentTemperature: celsius));
        }
      }, onError: ignore),
      _dataSource.watchTargetTemperature(deviceId).listen((celsius) {
        if (celsius != null) {
          _update((s) => s.copyWith(targetTemperature: celsius.round()));
        }
      }, onError: ignore),
      _dataSource
          .watchRegister1(deviceId)
          .listen(
            (r) => _update(
              (s) => s.copyWith(
                heaterOn: r.heaterOn,
                pumpOn: r.pumpOn,
                autoShutdown: r.autoShutdown,
              ),
            ),
            onError: ignore,
          ),
      _dataSource
          .watchRegister2(deviceId)
          .listen(
            (r) => _update(
              (s) => s.copyWith(
                fahrenheit: r.fahrenheit,
                displayOnCooling: r.displayOnCooling,
              ),
            ),
            onError: ignore,
          ),
    ]);
  }

  void _update(VolcanoStatus Function(VolcanoStatus) change) {
    final current = _status.value;
    if (current != null) _status.value = change(current);
  }

  /// Applies [change] optimistically, then writes. On failure the previous
  /// value is restored unless a notification has replaced it meanwhile.
  Future<Either<AppError, Unit>> _write(
    VolcanoStatus Function(VolcanoStatus) change,
    Future<void> Function(String deviceId) write,
  ) async {
    final deviceId = _deviceId;
    final previous = _status.value;
    if (deviceId == null || previous == null || !_sessionActive.value) {
      return left(const AppError.notConnected());
    }
    final optimistic = change(previous);
    _status.value = optimistic;
    try {
      await write(deviceId);
      return right(unit);
    } catch (e) {
      if (_status.value == optimistic) _status.value = previous;
      return left(_toAppError(e));
    }
  }

  AppError _toAppError(Object e) => switch (e) {
    VolcanoWriteNotAllowedException(:final characteristicUuid) =>
      AppError.writeNotVerified(characteristicUuid),
    _ => BleErrorMapper.toAppError(e),
  };

  Future<void> _teardown() async {
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    _deviceId = null;
    _sessionActive.value = false;
    _status.value = null;
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }
}
