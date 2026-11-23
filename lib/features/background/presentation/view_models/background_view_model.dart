import 'dart:async';
import 'dart:ui';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../portable/domain/use_cases/set_portable_polling_use_case.dart';
import '../../domain/models/heat_session.dart';
import '../../domain/models/ready_alert_state.dart';
import '../../domain/services/background_rules.dart';
import '../../domain/use_cases/alert_ready_use_case.dart';
import '../../domain/use_cases/current_heat_session_use_case.dart';
import '../../domain/use_cases/device_session_target_use_case.dart';
import '../../domain/use_cases/dismiss_ready_alert_use_case.dart';
import '../../domain/use_cases/reset_background_service_use_case.dart';
import '../../domain/use_cases/show_background_session_use_case.dart';
import '../../domain/use_cases/start_device_session_use_case.dart';
import '../extensions/heat_session_x.dart';

/// App-level, created once by `KilnApp`: keeps the active device's session
/// running, the background service and its notification in step with the
/// heat session, gives the "ready" alert and decides the Venty/Veazy poll,
/// following [BackgroundRules].
class BackgroundViewModel {
  BackgroundViewModel({
    CurrentHeatSessionUseCase? currentSession,
    ShowBackgroundSessionUseCase? showSession,
    AlertReadyUseCase? alertReady,
    DismissReadyAlertUseCase? dismissAlert,
    ResetBackgroundServiceUseCase? resetService,
    SetPortablePollingUseCase? setPortablePolling,
    DeviceSessionTargetUseCase? sessionTarget,
    StartDeviceSessionUseCase? startDeviceSession,
    BackgroundRules? rules,
    AppLifecycleService? lifecycle,
    L10nService? l10n,
  }) : _currentSession = currentSession ?? sl<CurrentHeatSessionUseCase>(),
       _showSession = showSession ?? sl<ShowBackgroundSessionUseCase>(),
       _alertReady = alertReady ?? sl<AlertReadyUseCase>(),
       _dismissAlert = dismissAlert ?? sl<DismissReadyAlertUseCase>(),
       _resetService = resetService ?? sl<ResetBackgroundServiceUseCase>(),
       _setPortablePolling =
           setPortablePolling ?? sl<SetPortablePollingUseCase>(),
       _sessionTarget = sessionTarget ?? sl<DeviceSessionTargetUseCase>(),
       _startDeviceSession =
           startDeviceSession ?? sl<StartDeviceSessionUseCase>(),
       _rules = rules ?? sl<BackgroundRules>(),
       _lifecycle = lifecycle ?? sl<AppLifecycleService>(),
       _l10n = l10n ?? sl<L10nService>() {
    // Queued before the first show, so a leftover service is gone first.
    unawaited(_resetService().then((_) {}));
    _effects
      ..add(effect(_syncService))
      ..add(effect(_syncPolling))
      ..add(effect(_keepDeviceSession));
  }

  final CurrentHeatSessionUseCase _currentSession;
  final ShowBackgroundSessionUseCase _showSession;
  final AlertReadyUseCase _alertReady;
  final DismissReadyAlertUseCase _dismissAlert;
  final ResetBackgroundServiceUseCase _resetService;
  final SetPortablePollingUseCase _setPortablePolling;
  final DeviceSessionTargetUseCase _sessionTarget;
  final StartDeviceSessionUseCase _startDeviceSession;
  final BackgroundRules _rules;
  final AppLifecycleService _lifecycle;
  final L10nService _l10n;
  final List<void Function()> _effects = [];
  HeatSession? _last;
  ReadyAlertState _alert = const ReadyAlertState();

  late final Computed<HeatSession?> session = computed(
    () => _last = _currentSession(previous: _last),
  );

  late final Computed<bool> _heating = computed(() => session.value != null);

  late final Computed<bool> _inFront = computed(() {
    final state = _lifecycle.state.value;
    return state != AppLifecycleState.hidden &&
        state != AppLifecycleState.paused;
  });

  void _syncService() {
    final current = session.value;
    final inFront = _inFront.value;
    // Tracked: a language change re-sends the notification.
    final strings = _l10n.strings;
    untracked(() {
      unawaited(_showSession(current?.notice(strings)).then((_) {}));
      final (next, action) = _rules.readyAlert(
        _alert,
        session: current,
        inFront: inFront,
      );
      _alert = next;
      switch (action) {
        case ReadyAlertAction.alert:
          unawaited(_alertReady(current!.readyNotice(strings)).then((_) {}));
        case ReadyAlertAction.dismiss:
          unawaited(_dismissAlert().then((_) {}));
        case ReadyAlertAction.none:
          break;
      }
    });
  }

  void _syncPolling() {
    final active = _rules.keepPolling(
      inFront: _inFront.value,
      heating: _heating.value,
    );
    untracked(() => _setPortablePolling(active: active));
  }

  late final Computed<({String id, DeviceModel model})?> _deviceTarget =
      computed(_sessionTarget.call);

  /// The device session runs while the active device is connected, also
  /// after a reconnect while another screen (or none) is shown. Errors are
  /// left to the device screens, which start the same session.
  void _keepDeviceSession() {
    final target = _deviceTarget.value;
    if (target == null) return;
    untracked(
      () =>
          unawaited(_startDeviceSession(target.id, target.model).then((_) {})),
    );
  }

  void dispose() {
    for (final dispose in _effects) {
      dispose();
    }
    session.dispose();
    _heating.dispose();
    _inFront.dispose();
    _deviceTarget.dispose();
  }
}
