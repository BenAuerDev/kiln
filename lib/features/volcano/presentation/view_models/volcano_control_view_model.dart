import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../../domain/extensions/volcano_status_x.dart';
import '../../domain/models/volcano_heat_phase.dart';
import '../../domain/models/volcano_status.dart';
import '../../domain/repositories/volcano_repository.dart';
import '../../domain/services/volcano_target_rules.dart';
import '../../domain/use_cases/adjust_volcano_target_use_case.dart';
import '../../domain/use_cases/set_volcano_target_use_case.dart';
import '../../domain/use_cases/start_volcano_session_use_case.dart';
import '../../domain/use_cases/stop_volcano_session_use_case.dart';
import '../../domain/use_cases/toggle_volcano_heater_use_case.dart';
import '../../domain/use_cases/toggle_volcano_pump_use_case.dart';
import '../navigation/volcano_navigator.dart';
import 'volcano_tab.dart';

class VolcanoControlViewModel {
  VolcanoControlViewModel({
    VolcanoRepository? repository,
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    StartVolcanoSessionUseCase? startSession,
    StopVolcanoSessionUseCase? stopSession,
    SetVolcanoTargetUseCase? setTarget,
    AdjustVolcanoTargetUseCase? adjustTarget,
    ToggleVolcanoHeaterUseCase? toggleHeater,
    ToggleVolcanoPumpUseCase? togglePump,
    HapticsService? haptics,
    ToastService? toasts,
    L10nService? l10n,
    VolcanoNavigator? navigator,
    this.savedFeedbackDelay = const Duration(milliseconds: 700),
  }) : _repository = repository ?? sl<VolcanoRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _startSession = startSession ?? sl<StartVolcanoSessionUseCase>(),
       _stopSession = stopSession ?? sl<StopVolcanoSessionUseCase>(),
       _setTarget = setTarget ?? sl<SetVolcanoTargetUseCase>(),
       _adjustTarget = adjustTarget ?? sl<AdjustVolcanoTargetUseCase>(),
       _toggleHeater = toggleHeater ?? sl<ToggleVolcanoHeaterUseCase>(),
       _togglePump = togglePump ?? sl<ToggleVolcanoPumpUseCase>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toasts = toasts ?? sl<ToastService>(),
       _l10n = l10n ?? sl<L10nService>(),
       _navigator = navigator ?? sl<VolcanoNavigator>() {
    _effects.add(effect(_syncSession));
  }

  final VolcanoRepository _repository;
  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final StartVolcanoSessionUseCase _startSession;
  final StopVolcanoSessionUseCase _stopSession;
  final SetVolcanoTargetUseCase _setTarget;
  final AdjustVolcanoTargetUseCase _adjustTarget;
  final ToggleVolcanoHeaterUseCase _toggleHeater;
  final ToggleVolcanoPumpUseCase _togglePump;
  final HapticsService _haptics;
  final ToastService _toasts;
  final L10nService _l10n;
  final VolcanoNavigator _navigator;

  /// Quiet period after the last −/+ step before "Saved to …" is shown.
  final Duration savedFeedbackDelay;

  final List<void Function()> _effects = [];
  Timer? _savedFeedback;

  List<int> get presets => VolcanoTargetRules.presets;

  ReadonlySignal<VolcanoStatus?> get status => _repository.status;

  ReadonlySignal<ConnectionStatus> get connectionStatus => _connection.status;

  /// Name of the active device, `null` if it is not a known device yet.
  late final Computed<String?> deviceName = computed(() {
    final id = _connection.activeDeviceId.value;
    return id == null ? null : _knownDevices.byId(id)?.model.displayName;
  });

  late final Computed<VolcanoHeatPhase?> phase = computed(
    () => _repository.status.value?.phase,
  );

  late final Computed<double> currentFraction = computed(
    () => _repository.status.value?.currentFraction ?? 0,
  );

  late final Computed<double> targetFraction = computed(
    () => _repository.status.value?.targetFraction ?? 0,
  );

  late final Computed<bool> controlsEnabled = computed(
    () => _repository.sessionActive.value && _repository.status.value != null,
  );

  void decreaseTarget() => unawaited(_step(-1));

  void increaseTarget() => unawaited(_step(1));

  Future<void> selectPreset(int celsius) async {
    (await _setTarget(celsius)).match(_showError, (written) {
      if (written.isSome()) _confirmSaved();
    });
  }

  Future<void> toggleHeater() async {
    (await _toggleHeater()).match(_showError, (_) => _confirmSaved());
  }

  Future<void> togglePump() async {
    (await _togglePump()).match(_showError, (_) => _confirmSaved());
  }

  void selectTab(VolcanoTab tab) {
    if (tab == VolcanoTab.devices) _navigator.goToDevices();
  }

  void dispose() {
    _savedFeedback?.cancel();
    for (final dispose in _effects) {
      dispose();
    }
    deviceName.dispose();
    phase.dispose();
    currentFraction.dispose();
    targetFraction.dispose();
    controlsEnabled.dispose();
  }

  void _syncSession() {
    final deviceId = _connection.activeDeviceId.value;
    final connected = _connection.status.value == ConnectionStatus.connected;
    untracked(() {
      if (connected && deviceId != null) {
        unawaited(_start(deviceId));
      } else if (_repository.sessionActive.value) {
        unawaited(_stopSession());
      }
    });
  }

  Future<void> _start(String deviceId) async {
    (await _startSession(deviceId)).match((error) {
      // A start superseded by a newer connection change is not worth a toast.
      if (error is! NotConnectedError) _showError(error);
    }, (_) {});
  }

  Future<void> _step(int delta) async {
    (await _adjustTarget(delta)).match(_showError, (written) {
      if (written.isNone()) return;
      unawaited(_haptics.tick());
      _savedFeedback?.cancel();
      _savedFeedback = Timer(savedFeedbackDelay, _confirmSaved);
    });
  }

  /// Haptic only: the Volcano's own display already shows every change.
  void _confirmSaved() {
    _savedFeedback?.cancel();
    _savedFeedback = null;
    unawaited(_haptics.success());
  }

  void _showError(AppError error) {
    unawaited(_haptics.warning());
    _toasts.show(error.message(_l10n.strings), level: ToastLevel.error);
  }
}
