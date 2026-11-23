import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/models/known_device.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../../domain/models/portable_status.dart';
import '../../domain/repositories/portable_repository.dart';
import '../../domain/use_cases/start_portable_session_use_case.dart';
import '../../domain/use_cases/stop_portable_session_use_case.dart';

/// What every portable view model shares: the active device, the session
/// start, serialised writes and the haptic/toast feedback.
///
/// Each view model owns one instance and disposes it.
class PortableSessionBinding {
  PortableSessionBinding({
    PortableRepository? repository,
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    StartPortableSessionUseCase? startSession,
    StopPortableSessionUseCase? stopSession,
    HapticsService? haptics,
    ToastService? toasts,
    L10nService? l10n,
    this.savedFeedbackDelay = const Duration(milliseconds: 700),
  }) : _repository = repository ?? sl<PortableRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _startSession = startSession ?? sl<StartPortableSessionUseCase>(),
       _stopSession = stopSession ?? sl<StopPortableSessionUseCase>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toasts = toasts ?? sl<ToastService>(),
       _l10n = l10n ?? sl<L10nService>() {
    _effects.add(effect(_syncSession));
  }

  final PortableRepository _repository;
  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final StartPortableSessionUseCase _startSession;
  final StopPortableSessionUseCase _stopSession;
  final HapticsService _haptics;
  final ToastService _toasts;
  final L10nService _l10n;

  /// Quiet period after the last −/+ step before "Saved to …" is shown.
  final Duration savedFeedbackDelay;

  final List<void Function()> _effects = [];
  Timer? _savedFeedback;
  Future<void> _writes = Future.value();
  bool _disposed = false;

  ReadonlySignal<PortableStatus?> get status => _repository.status;

  ReadonlySignal<ConnectionStatus> get connectionStatus => _connection.status;

  /// The active known device, `null` until it has been saved.
  late final Computed<KnownDevice?> device = computed(() {
    final id = _connection.activeDeviceId.value;
    return id == null ? null : _knownDevices.byId(id);
  });

  late final Computed<String> deviceName = computed(
    () => device.value?.model.displayName ?? _l10n.strings.portableDefaultName,
  );

  late final Computed<bool> controlsEnabled = computed(
    () => _repository.sessionActive.value && _repository.status.value != null,
  );

  /// Device and model a session should run for, `null` when none should.
  late final Computed<(String, DeviceModel)?> _sessionTarget = computed(() {
    final device = this.device.value;
    final connected = _connection.status.value == ConnectionStatus.connected;
    if (!connected || device == null || !device.model.isPortable) return null;
    return (device.id, device.model);
  });

  /// Light tick for a −/+ step, then the write. Steps are written one after
  /// another, and "Saved to …" follows once they settle.
  Future<void> step(Future<Either<AppError, Option<int>>> Function() adjust) {
    unawaited(_haptics.tick());
    return write(() async {
      (await adjust()).match(showError, (written) {
        if (written.isNone()) {
          unawaited(_haptics.warning());
        } else {
          _scheduleSaved();
        }
      });
    });
  }

  /// Runs [job] after every earlier write has finished.
  Future<void> write(Future<void> Function() job) {
    final next = _writes.then((_) => job());
    _writes = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  void tick() => unawaited(_haptics.tick());

  void confirmSaved() {
    _savedFeedback?.cancel();
    _savedFeedback = null;
    if (_disposed) return;
    unawaited(_haptics.success());
    _toasts.show(
      _l10n.strings.commonSavedTo(deviceName.value),
      level: ToastLevel.success,
    );
  }

  void showError(AppError error) {
    if (_disposed) return;
    unawaited(_haptics.warning());
    _toasts.show(error.message(_l10n.strings), level: ToastLevel.error);
  }

  void dispose() {
    _disposed = true;
    _savedFeedback?.cancel();
    for (final dispose in _effects) {
      dispose();
    }
    _sessionTarget.dispose();
    device.dispose();
    deviceName.dispose();
    controlsEnabled.dispose();
  }

  void _syncSession() {
    final target = _sessionTarget.value;
    untracked(() {
      if (target != null) {
        unawaited(_start(target.$1, target.$2));
      } else if (_repository.sessionActive.value) {
        unawaited(_stopSession());
      }
    });
  }

  Future<void> _start(String deviceId, DeviceModel model) async {
    (await _startSession(deviceId, model)).match((error) {
      // A start superseded by a newer connection change is not worth a toast.
      if (error is! NotConnectedError) showError(error);
    }, (_) {});
  }

  void _scheduleSaved() {
    if (_disposed) return;
    _savedFeedback?.cancel();
    _savedFeedback = Timer(savedFeedbackDelay, confirmSaved);
  }
}
