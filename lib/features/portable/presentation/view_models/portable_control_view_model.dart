import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../domain/extensions/portable_status_x.dart';
import '../../domain/models/heater_mode.dart';
import '../../domain/models/portable_heat_phase.dart';
import '../../domain/models/portable_status.dart';
import '../../domain/services/portable_control_rules.dart';
import '../../domain/services/portable_ladder_service.dart';
import '../../domain/use_cases/adjust_base_temperature_use_case.dart';
import '../../domain/use_cases/set_base_temperature_use_case.dart';
import '../../domain/use_cases/toggle_portable_boost_use_case.dart';
import '../../domain/use_cases/toggle_portable_heater_use_case.dart';
import '../navigation/portable_navigator.dart';
import 'portable_session_binding.dart';
import 'portable_tab.dart';

/// Live temperature, base target, presets, heater and boost.
class PortableControlViewModel {
  PortableControlViewModel({
    PortableSessionBinding? session,
    PortableLadderService? ladderService,
    AdjustBaseTemperatureUseCase? adjustBase,
    SetBaseTemperatureUseCase? setBase,
    TogglePortableHeaterUseCase? toggleHeater,
    TogglePortableBoostUseCase? toggleBoost,
    PortableNavigator? navigator,
  }) : _session = session ?? sl<PortableSessionBinding>(),
       _ladderService = ladderService ?? sl<PortableLadderService>(),
       _adjustBase = adjustBase ?? sl<AdjustBaseTemperatureUseCase>(),
       _setBase = setBase ?? sl<SetBaseTemperatureUseCase>(),
       _toggleHeater = toggleHeater ?? sl<TogglePortableHeaterUseCase>(),
       _toggleBoost = toggleBoost ?? sl<TogglePortableBoostUseCase>(),
       _navigator = navigator ?? sl<PortableNavigator>();

  final PortableSessionBinding _session;
  final PortableLadderService _ladderService;
  final AdjustBaseTemperatureUseCase _adjustBase;
  final SetBaseTemperatureUseCase _setBase;
  final TogglePortableHeaterUseCase _toggleHeater;
  final TogglePortableBoostUseCase _toggleBoost;
  final PortableNavigator _navigator;

  List<int> get presets => PortableControlRules.presets;

  ReadonlySignal<PortableStatus?> get status => _session.status;

  ReadonlySignal<ConnectionStatus> get connectionStatus =>
      _session.connectionStatus;

  ReadonlySignal<String> get deviceName => _session.deviceName;

  ReadonlySignal<bool> get controlsEnabled => _session.controlsEnabled;

  late final Computed<PortableHeatPhase?> phase = computed(
    () => _session.status.value?.heatPhase,
  );

  /// The temperature the heater aims for, boost included.
  late final Computed<int?> activeTarget = computed(() {
    final status = _session.status.value;
    return status == null ? null : _ladderService.activeTemperature(status);
  });

  late final Computed<double> targetPosition = computed(() {
    final status = _session.status.value;
    return status == null ? 0 : _ladderService.activePosition(status);
  });

  late final Computed<double> gaugeProgress = computed(
    () => _session.status.value?.gaugeProgress(targetPosition.value) ?? 0,
  );

  void decreaseTarget() => unawaited(_session.step(() => _adjustBase(-1)));

  void increaseTarget() => unawaited(_session.step(() => _adjustBase(1)));

  Future<void> selectPreset(int celsius) {
    _session.tick();
    return _session.write(() async {
      (await _setBase(celsius)).match(_session.showError, (written) {
        if (written.isSome()) _session.confirmSaved();
      });
    });
  }

  Future<void> toggleHeater() => _writeHeaterMode(_toggleHeater.call);

  Future<void> toggleBoost() => _writeHeaterMode(_toggleBoost.call);

  void selectTab(PortableTab tab) {
    if (tab != PortableTab.control) _navigator.goToTab(tab);
  }

  void dispose() {
    phase.dispose();
    activeTarget.dispose();
    targetPosition.dispose();
    gaugeProgress.dispose();
    _session.dispose();
  }

  Future<void> _writeHeaterMode(
    Future<Either<AppError, HeaterMode>> Function() toggle,
  ) {
    _session.tick();
    return _session.write(() async {
      (await toggle()).match(
        _session.showError,
        (_) => _session.confirmSaved(),
      );
    });
  }
}
