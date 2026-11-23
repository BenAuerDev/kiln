import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/ble/ble_connection_state.dart';
import '../../../../core/ble/ble_error_mapper.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../data/data_sources/portable_ble_data_source.dart';
import '../../data/models/portable_device_settings_dto.dart';
import '../../data/models/portable_firmware_info_dto.dart';
import '../../data/models/portable_identity_dto.dart';
import '../../data/models/portable_packets.dart';
import '../../data/models/portable_protocol.dart';
import '../../data/models/portable_status_dto.dart';
import '../../data/safety/portable_write_safety.dart';
import '../models/heater_mode.dart';
import '../models/portable_settings.dart';
import '../models/portable_status.dart';
import '../services/portable_temperature_limits.dart';

/// Fields whose incoming values are ignored for a short time after kiln wrote
/// them, so a poll reply that was already on its way does not flicker the UI
/// back to the old value.
enum _HeldField { target, boost, superBoost, heater, settings }

/// Owns the Venty/Veazy session: notifications, the init sequence, the
/// 500 ms status poll and all writes.
class PortableRepository {
  PortableRepository({
    PortableBleDataSource? dataSource,
    this._pollInterval = const Duration(milliseconds: 500),
    this._replyTimeout = const Duration(seconds: 2),
    this._firmwareInfoAttempts = 3,
    this._writeHold = const Duration(milliseconds: 1500),
    this._clock = DateTime.now,
  }) : _dataSource = dataSource ?? sl<PortableBleDataSource>();

  final PortableBleDataSource _dataSource;
  final Duration _pollInterval;
  final Duration _replyTimeout;
  final int _firmwareInfoAttempts;
  final Duration _writeHold;
  final DateTime Function() _clock;

  final _status = signal<PortableStatus?>(null);
  final _sessionActive = signal<bool>(false);
  final _statusUpdatedAt = signal<DateTime?>(null);
  final _sessionNumber = signal<int>(0);
  final _startFailed = signal<bool>(false);

  String? _deviceId;
  DeviceModel? _model;
  int _generation = 0;
  Future<Either<AppError, Unit>>? _starting;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<BleConnectionState>? _connectionSubscription;
  Completer<PortableFirmwareInfoDto>? _firmwareReply;
  Completer<PortableIdentityDto>? _identityReply;
  Future<Either<AppError, Option<int>>>? _colorRead;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  /// Survives sessions: set while the app is in the background.
  bool _pollingPaused = false;

  /// Vibration comes from the `0x06` reply, not from the status packet.
  bool? _vibration;
  final Map<_HeldField, Timer> _holds = {};

  /// `null` until the first status notification of a session.
  ReadonlySignal<PortableStatus?> get status => _status;

  /// `true` once the init sequence finished and the poll runs.
  ReadonlySignal<bool> get sessionActive => _sessionActive;

  /// Goes up by one each time a session starts, so state tied to a session
  /// (a finished ramp) can tell a new session from the one it belongs to.
  ReadonlySignal<int> get sessionNumber => _sessionNumber;

  /// The last session start failed (and was not superseded): the device is
  /// connected but reports nothing. Reset by the next start.
  ReadonlySignal<bool> get startFailed => _startFailed;

  /// When the last status packet arrived; `null` without a session. Stops
  /// moving while polling is paused (app in the background), so callers that
  /// act on the status can tell it is stale.
  ReadonlySignal<DateTime?> get statusUpdatedAt => _statusUpdatedAt;

  /// Starts notifications, runs the init sequence and the status poll.
  /// Idempotent for the same device. Starting for another device stops the
  /// current session first.
  Future<Either<AppError, Unit>> startSession(
    String deviceId,
    DeviceModel model,
  ) {
    if (model != DeviceModel.venty && model != DeviceModel.veazy) {
      return Future.value(left(AppError.protocol('not a portable: $model')));
    }
    if (_deviceId == deviceId && _model == model) {
      if (_sessionActive.value) return Future.value(right(unit));
      final starting = _starting;
      if (starting != null) return starting;
    }
    _teardown();
    _startFailed.value = false;
    final generation = _generation;
    _deviceId = deviceId;
    _model = model;
    final starting = _runInit(deviceId, generation);
    _starting = starting;
    return starting;
  }

  Future<void> stopSession() async => _teardown();

  Future<Either<AppError, Unit>> setTargetTemperature(int celsius) => _write(
    PortableWrite.targetTemperature,
    () => PortablePackets.targetTemperature(celsius),
    onSuccess: () {
      _hold(_HeldField.target);
      _updateStatus((s) => s.copyWith(targetTemperature: celsius));
    },
  );

  Future<Either<AppError, Unit>> setBoostOffset(int offset) => _write(
    PortableWrite.boostOffset,
    () => PortablePackets.boostOffset(offset),
    onSuccess: () {
      _hold(_HeldField.boost);
      _updateStatus((s) => s.copyWith(boostOffset: offset));
    },
  );

  Future<Either<AppError, Unit>> setSuperBoostOffset(int offset) => _write(
    PortableWrite.superBoostOffset,
    () => PortablePackets.superBoostOffset(offset),
    onSuccess: () {
      _hold(_HeldField.superBoost);
      _updateStatus((s) => s.copyWith(superBoostOffset: offset));
    },
  );

  Future<Either<AppError, Unit>> setHeaterMode(HeaterMode mode) => _write(
    switch (mode) {
      HeaterMode.off => PortableWrite.heaterOff,
      HeaterMode.normal => PortableWrite.heaterOn,
      HeaterMode.boost => PortableWrite.heaterBoost,
      HeaterMode.superboost => PortableWrite.heaterSuperBoost,
    },
    () => switch (mode) {
      HeaterMode.boost => PortablePackets.heaterBoost(),
      HeaterMode.superboost => PortablePackets.heaterSuperBoost(),
      _ => PortablePackets.heater(on: mode == HeaterMode.normal),
    },
    onSuccess: () {
      _hold(_HeldField.heater);
      _updateStatus((s) => s.copyWith(heaterMode: mode));
    },
  );

  /// Writes only the settings that differ from the current status, one
  /// packet per setting like the official app.
  Future<Either<AppError, Unit>> setSettings(PortableSettings settings) async {
    if (!_sessionActive.value) return left(const AppError.notConnected());
    final current = _status.value?.settings;
    final isVeazy = _model == DeviceModel.veazy;

    Future<Either<AppError, Unit>> writeSetting(
      PortableWritableSetting setting,
      bool set,
      PortableSettings Function(PortableSettings) apply,
    ) => _write(
      PortableWrite.setting,
      () => PortablePackets.setting(setting, set: set),
      onSuccess: () {
        _hold(_HeldField.settings);
        _updateStatus((s) => s.copyWith(settings: apply(s.settings)));
      },
    );

    final writes = <Future<Either<AppError, Unit>> Function()>[
      if (current?.fahrenheit != settings.fahrenheit)
        () => writeSetting(
          PortableWritableSetting.fahrenheit,
          settings.fahrenheit,
          (s) => s.copyWith(fahrenheit: settings.fahrenheit),
        ),
      if (current?.ecoCharge != settings.ecoCharge)
        () => writeSetting(
          PortableWritableSetting.ecoCharge,
          settings.ecoCharge,
          (s) => s.copyWith(ecoCharge: settings.ecoCharge),
        ),
      if (current?.ecoVoltage != settings.ecoVoltage)
        () => writeSetting(
          PortableWritableSetting.ecoVoltage,
          settings.ecoVoltage,
          (s) => s.copyWith(ecoVoltage: settings.ecoVoltage),
        ),
      if (current?.boostVisualisation != settings.boostVisualisation)
        () => writeSetting(
          PortableWritableSetting.boostVisualisation,
          // On a Veazy the bit is inverted (set = visualisation off).
          settings.boostVisualisation != isVeazy,
          (s) => s.copyWith(boostVisualisation: settings.boostVisualisation),
        ),
      if (current?.vibrateWhenReady != settings.vibrateWhenReady)
        () => _write(
          PortableWrite.vibration,
          () => PortablePackets.vibration(on: settings.vibrateWhenReady),
          onSuccess: () {
            _vibration = settings.vibrateWhenReady;
            _updateStatus(
              (s) => s.copyWith(
                settings: s.settings.copyWith(
                  vibrateWhenReady: settings.vibrateWhenReady,
                ),
              ),
            );
          },
        ),
    ];
    for (final write in writes) {
      final result = await write();
      if (result.isLeft()) return result;
    }
    return right(unit);
  }

  /// Reads the colour index the device reports in its identity reply.
  /// `none()` when the reply carries no colour byte.
  /// A read that is already under way is shared, not sent twice (the second
  /// request would orphan the first one's reply).
  Future<Either<AppError, Option<int>>> readColorIndex() =>
      _colorRead ??= _readColorIndex().whenComplete(() => _colorRead = null);

  Future<Either<AppError, Option<int>>> _readColorIndex() async {
    final reply = _identityReply = Completer<PortableIdentityDto>();
    reply.future.ignore();
    final sent = await _write(
      PortableWrite.identityRead,
      PortablePackets.identityRequest,
    );
    if (sent.isLeft()) {
      _identityReply = null;
      return sent.map((_) => none());
    }
    try {
      final identity = await reply.future.timeout(_replyTimeout);
      return right(Option.fromNullable(identity.colorIndex));
    } on TimeoutException {
      return left(const AppError.timeout());
    } on AppError catch (e) {
      return left(e);
    } finally {
      if (identical(_identityReply, reply)) _identityReply = null;
    }
  }

  Future<Either<AppError, Unit>> findDevice() =>
      _write(PortableWrite.findDevice, PortablePackets.findDevice);

  // ---------------------------------------------------------------- session

  /// Init per docs/protocol.md, reduced to the packets kiln needs:
  /// notify → `02` (abort in bootloader mode) → `01 00` → `06 00…` → poll.
  /// `1D`, `04`, `23`, `05` and `30 06` are skipped on purpose.
  Future<Either<AppError, Unit>> _runInit(
    String deviceId,
    int generation,
  ) async {
    final firmwareReply = _firmwareReply = Completer<PortableFirmwareInfoDto>();
    // Errors may arrive before anyone awaits the reply.
    firmwareReply.future.ignore();
    try {
      _subscription = _dataSource
          .subscribe(deviceId)
          .listen(_onPacket, onError: _onStreamError, onDone: _onStreamDone);
      _connectionSubscription = _dataSource
          .connectionState(deviceId)
          .listen(
            (state) {
              if (state == BleConnectionState.disconnected &&
                  generation == _generation) {
                _teardown();
              }
            },
            onError: (Object _) {
              if (generation == _generation) _teardown();
            },
          );
      await _dataSource.enableNotifications(deviceId);

      PortableFirmwareInfoDto? info;
      for (var attempt = 1; info == null; attempt++) {
        if (generation != _generation) {
          return left(const AppError.notConnected());
        }
        // Retried as a safety net in case the first reply is lost.
        await _dataSource.write(
          deviceId,
          PortablePackets.firmwareInfoRequest(),
        );
        if (generation != _generation) {
          return left(const AppError.notConnected());
        }
        try {
          info = await firmwareReply.future.timeout(_replyTimeout);
        } on TimeoutException {
          if (attempt >= _firmwareInfoAttempts) rethrow;
        }
      }
      if (generation != _generation) return left(const AppError.notConnected());
      if (!info.applicationRunning) {
        _teardown();
        _startFailed.value = true;
        return left(const AppError.protocol('device is in bootloader mode'));
      }

      for (final packet in [
        PortablePackets.statusPoll(),
        PortablePackets.deviceSettingsRead(),
      ]) {
        await _dataSource.write(deviceId, packet);
        if (generation != _generation) {
          return left(const AppError.notConnected());
        }
      }

      _firmwareReply = null;
      _starting = null;
      _sessionNumber.value++;
      _sessionActive.value = true;
      if (!_pollingPaused) _startPollTimer();
      return right(unit);
    } on TimeoutException {
      _failStart(generation);
      return left(const AppError.timeout());
    } catch (e) {
      _failStart(generation);
      return left(BleErrorMapper.toAppError(e));
    }
  }

  /// Stops the status poll while the app is in the background, so the device
  /// can go to sleep. The session and connection stay up.
  void pausePolling() {
    _pollingPaused = true;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Polls immediately, then every 500 ms again.
  void resumePolling() {
    _pollingPaused = false;
    if (!_sessionActive.value || _pollTimer != null) return;
    _startPollTimer();
    unawaited(_poll());
  }

  void _startPollTimer() {
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_poll()));
  }

  Future<void> _poll() async {
    final deviceId = _deviceId;
    if (_pollInFlight || deviceId == null) return;
    _pollInFlight = true;
    try {
      await _dataSource.write(deviceId, PortablePackets.statusPoll());
    } catch (_) {
      // A lost connection is handled by ConnectionRepository; the next tick
      // tries again.
    } finally {
      _pollInFlight = false;
    }
  }

  void _onStreamError(Object error) {
    final reply = _firmwareReply;
    if (reply != null && !reply.isCompleted) {
      reply.completeError(error);
    } else if (_sessionActive.value) {
      _teardown();
    }
  }

  void _onStreamDone() {
    final reply = _firmwareReply;
    if (reply != null && !reply.isCompleted) {
      reply.completeError(const AppError.connectionLost());
    } else if (_sessionActive.value) {
      _teardown();
    }
  }

  void _failStart(int generation) {
    if (generation != _generation) return;
    _teardown();
    _startFailed.value = true;
  }

  /// Stops everything and invalidates a running init.
  void _teardown() {
    _generation++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
    for (final timer in _holds.values) {
      timer.cancel();
    }
    _holds.clear();
    final reply = _firmwareReply;
    if (reply != null && !reply.isCompleted) {
      reply.completeError(const AppError.notConnected());
    }
    _firmwareReply = null;
    final identityReply = _identityReply;
    if (identityReply != null && !identityReply.isCompleted) {
      identityReply.completeError(const AppError.notConnected());
    }
    _identityReply = null;
    _starting = null;
    _deviceId = null;
    _model = null;
    _vibration = null;
    _sessionActive.value = false;
    _status.value = null;
    _statusUpdatedAt.value = null;
    final connectionSubscription = _connectionSubscription;
    _connectionSubscription = null;
    unawaited(connectionSubscription?.cancel());
    final subscription = _subscription;
    _subscription = null;
    // Not awaited: nothing depends on it, and the new session must not wait.
    unawaited(subscription?.cancel());
  }

  // ---------------------------------------------------------- notifications

  void _onPacket(List<int> bytes) {
    if (bytes.isEmpty) return;
    try {
      switch (bytes[0]) {
        case PortableCommand.status:
          _applyStatus(PortableStatusDto.decode(bytes));
        case PortableCommand.firmwareInfo:
          final reply = _firmwareReply;
          if (reply != null && !reply.isCompleted) {
            reply.complete(PortableFirmwareInfoDto.decode(bytes));
          }
        case PortableCommand.deviceSettings:
          _applyDeviceSettings(PortableDeviceSettingsDto.decode(bytes));
        case PortableCommand.identity:
          final reply = _identityReply;
          if (reply != null && !reply.isCompleted) {
            reply.complete(PortableIdentityDto.decode(bytes));
          }
      }
    } on FormatException {
      // Malformed packet: skip it, the next poll brings a fresh one.
    }
  }

  void _applyStatus(PortableStatusDto dto) {
    _statusUpdatedAt.value = _clock();
    final previous = _status.value;
    final isVeazy = _model == DeviceModel.veazy;
    final decoded = PortableStatus(
      currentTemperature: dto.currentTemperatureTenths == null
          ? null
          : dto.currentTemperatureTenths! / 10,
      targetTemperature: (dto.targetTemperatureTenths / 10).round(),
      boostOffset: dto.boostOffset,
      superBoostOffset: dto.superBoostOffset,
      batteryPercent: dto.batteryPercent,
      charging: dto.chargerConnected,
      heaterMode: _heaterMode(dto.heaterModeCode),
      autoOffSeconds: dto.autoOffSeconds,
      settings: PortableSettings(
        fahrenheit: dto.hasSetting(PortableSettingsBit.fahrenheit),
        vibrateWhenReady:
            _vibration ?? previous?.settings.vibrateWhenReady ?? false,
        ecoCharge: dto.hasSetting(PortableSettingsBit.ecoCharge),
        ecoVoltage: dto.hasSetting(PortableSettingsBit.ecoVoltage),
        boostVisualisation:
            dto.hasSetting(PortableSettingsBit.boostVisualisation) != isVeazy,
      ),
      setpointReached: dto.hasSetting(PortableSettingsBit.setpointReached),
    );
    // While boosting, bytes 4–5 hold the boosted setpoint, not the base
    // (seen on a Veazy: base 185 + 15 reads 200). The "changed on device"
    // bit cannot gate this: that Veazy sets it in every packet.
    final boosting =
        decoded.heaterMode == HeaterMode.boost ||
        decoded.heaterMode == HeaterMode.superboost;
    if (previous == null) {
      _status.value = boosting
          ? decoded.copyWith(targetTemperature: _baseWhileBoosting(decoded))
          : decoded;
      return;
    }
    final keepTarget = _isHeld(_HeldField.target) || boosting;
    _status.value = decoded.copyWith(
      targetTemperature: keepTarget ? previous.targetTemperature : null,
      boostOffset: _isHeld(_HeldField.boost) ? previous.boostOffset : null,
      superBoostOffset: _isHeld(_HeldField.superBoost)
          ? previous.superBoostOffset
          : null,
      heaterMode: _isHeld(_HeldField.heater) ? previous.heaterMode : null,
      settings: _isHeld(_HeldField.settings)
          ? previous.settings.copyWith(
              vibrateWhenReady: decoded.settings.vibrateWhenReady,
            )
          : null,
    );
  }

  /// Best guess when a session starts mid-boost: exact unless the boosted
  /// value hit the 210 °C cap. Corrected by the first packet after boost.
  int _baseWhileBoosting(PortableStatus status) {
    final offsets =
        status.boostOffset +
        (status.heaterMode == HeaterMode.superboost
            ? status.superBoostOffset
            : 0);
    return PortableTemperatureLimits.clampTemperature(
      status.targetTemperature - offsets,
    );
  }

  void _applyDeviceSettings(PortableDeviceSettingsDto dto) {
    _vibration = dto.vibrationOn;
    _updateStatus(
      (s) => s.copyWith(
        settings: s.settings.copyWith(vibrateWhenReady: dto.vibrationOn),
      ),
    );
  }

  HeaterMode _heaterMode(int code) => switch (code) {
    PortableHeaterModeCode.normal => HeaterMode.normal,
    PortableHeaterModeCode.boost => HeaterMode.boost,
    PortableHeaterModeCode.superBoost => HeaterMode.superboost,
    _ => HeaterMode.off,
  };

  // ----------------------------------------------------------------- writes

  Future<Either<AppError, Unit>> _write(
    PortableWrite write,
    List<int> Function() build, {
    void Function()? onSuccess,
  }) async {
    final deviceId = _deviceId;
    if (!_sessionActive.value || deviceId == null) {
      return left(const AppError.notConnected());
    }
    final heaterMode = _status.value?.heaterMode;
    final boostActive =
        heaterMode == HeaterMode.boost || heaterMode == HeaterMode.superboost;
    if (!PortableWriteSafety.isAllowed(write, boostActive: boostActive)) {
      return left(AppError.writeNotVerified(write.name));
    }
    try {
      await _dataSource.write(deviceId, build());
    } catch (e) {
      return left(BleErrorMapper.toAppError(e));
    }
    onSuccess?.call();
    return right(unit);
  }

  void _updateStatus(PortableStatus Function(PortableStatus) update) {
    final current = _status.value;
    if (current != null) _status.value = update(current);
  }

  void _hold(_HeldField field) {
    _holds[field]?.cancel();
    _holds[field] = Timer(_writeHold, () => _holds.remove(field));
  }

  bool _isHeld(_HeldField field) => _holds.containsKey(field);
}
