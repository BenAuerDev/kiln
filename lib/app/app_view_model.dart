import 'dart:async';
import 'dart:ui';

import 'package:signals_flutter/signals_flutter.dart';

import '../core/l10n/l10n_service.dart';
import '../core/service_locator.dart';
import '../core/services/app_lifecycle_service.dart';
import '../core/services/haptics_service.dart';
import '../core/services/system_locale_service.dart';
import '../core/theme/kiln_palette.dart';
import '../core/theme/kiln_tokens.dart';
import '../features/app_settings/domain/repositories/app_settings_repository.dart';
import '../features/devices/domain/extensions/known_device_x.dart';
import '../features/devices/domain/repositories/connection_repository.dart';
import '../features/devices/domain/repositories/known_devices_repository.dart';
import '../features/devices/domain/services/welcome_gate.dart';
import '../features/devices/domain/use_cases/reconnect_last_device_use_case.dart';
import '../features/devices/presentation/extensions/device_finish_x.dart';
import '../features/portable/domain/repositories/portable_repository.dart';
import '../features/portable/domain/use_cases/sync_portable_reconnect_use_case.dart';
import '../features/workflows/domain/models/workflow_run.dart';
import '../features/workflows/domain/repositories/workflow_run_repository.dart';
import '../features/workflows/domain/services/workflow_step_service.dart';
import '../features/workflows/domain/use_cases/stop_workflow_run_use_case.dart';

class AppViewModel {
  AppViewModel({
    AppSettingsRepository? settings,
    KnownDevicesRepository? knownDevices,
    AppLifecycleService? lifecycle,
    SystemLocaleService? systemLocale,
    L10nService? l10n,
    ReconnectLastDeviceUseCase? reconnectLastDevice,
    PortableRepository? portable,
    SyncPortableReconnectUseCase? syncPortableReconnect,
    ConnectionRepository? connection,
    StopWorkflowRunUseCase? stopWorkflowRun,
    WorkflowRunRepository? workflowRuns,
    WorkflowStepService? workflowSteps,
    HapticsService? haptics,
  }) : _settings = settings ?? sl<AppSettingsRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _lifecycle = lifecycle ?? sl<AppLifecycleService>(),
       _systemLocale = systemLocale ?? sl<SystemLocaleService>(),
       _l10n = l10n ?? sl<L10nService>(),
       _reconnectLastDevice =
           reconnectLastDevice ?? sl<ReconnectLastDeviceUseCase>(),
       _portable = portable ?? sl<PortableRepository>(),
       _syncPortableReconnect =
           syncPortableReconnect ?? sl<SyncPortableReconnectUseCase>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _stopWorkflowRun = stopWorkflowRun ?? sl<StopWorkflowRunUseCase>(),
       _workflowRuns = workflowRuns ?? sl<WorkflowRunRepository>(),
       _workflowSteps = workflowSteps ?? sl<WorkflowStepService>(),
       _haptics = haptics ?? sl<HapticsService>() {
    // Before kiln lets go of a Volcano, a workflow on it is stopped, so the
    // pump and heater are not left running out of reach.
    _connection.beforeRelease = (deviceId) =>
        _stopWorkflowRun(deviceId: deviceId).then((_) {});
    _effects
      ..add(
        effect(() {
          final preferred = switch (locale.value) {
            final Locale override => [override],
            null => _systemLocale.locales.value,
          };
          untracked(() => _l10n.updateLocales(preferred));
        }),
      )
      ..add(
        effect(() {
          // The Venty/Veazy poll follows BackgroundViewModel (it keeps
          // polling in the background while a heater is on).
          if (_lifecycle.state.value == AppLifecycleState.resumed) {
            untracked(() => unawaited(_reconnectLastDevice()));
          }
        }),
      )
      ..add(
        effect(() {
          // A null status means the session just ended; keep the last
          // decision so the drop that ended it is judged by it.
          final status = _portable.status.value;
          if (status != null) untracked(() => _syncPortableReconnect(status));
        }),
      )
      ..add(
        effect(() {
          // A buzz when a workflow step is reached, on whatever screen.
          final run = _workflowRuns.run.value;
          untracked(() {
            if (_workflowSteps.reachedMilestone(_lastRun, run)) {
              unawaited(_haptics.success());
            }
            _lastRun = run;
          });
        }),
      );
  }

  final AppSettingsRepository _settings;
  final KnownDevicesRepository _knownDevices;
  final AppLifecycleService _lifecycle;
  final SystemLocaleService _systemLocale;
  final L10nService _l10n;
  final ReconnectLastDeviceUseCase _reconnectLastDevice;
  final PortableRepository _portable;
  final SyncPortableReconnectUseCase _syncPortableReconnect;
  final ConnectionRepository _connection;
  final StopWorkflowRunUseCase _stopWorkflowRun;
  final WorkflowRunRepository _workflowRuns;
  final WorkflowStepService _workflowSteps;
  final HapticsService _haptics;
  WorkflowRun? _lastRun;
  final List<void Function()> _effects = [];

  /// Drives the router redirect: until the welcome is completed or a device
  /// is known (saved, or the demo device), only the welcome and the demo
  /// picker are reachable. A device paired from the devices screen during a
  /// demo therefore keeps the app past the welcome.
  late final Computed<bool> pastWelcome = computed(
    () => WelcomeGate.isPast(
      welcomeCompleted: _settings.welcomeCompleted.value,
      devices: _knownDevices.devices.value,
    ),
  );

  late final Computed<Locale?> locale = computed(() {
    final code = _settings.localeCode.value;
    return code == null ? null : Locale(code);
  });

  late final Computed<KilnFinishTokens> finish = computed(
    () =>
        _knownDevices.activeDevice.value?.effectiveFinish.tokens ??
        KilnPalette.ember,
  );

  /// Follows the language the app is rendered in.
  late final Computed<String> title = computed(() => _l10n.strings.appTitle);

  void dispose() {
    _connection.beforeRelease = null;
    for (final dispose in _effects) {
      dispose();
    }
    pastWelcome.dispose();
    locale.dispose();
    finish.dispose();
    title.dispose();
  }
}
