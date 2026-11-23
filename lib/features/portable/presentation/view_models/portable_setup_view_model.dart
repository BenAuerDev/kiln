import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../domain/models/portable_ladder.dart';
import '../../domain/models/portable_status.dart';
import '../../domain/models/quick_setup.dart';
import '../../domain/services/portable_ladder_service.dart';
import '../../domain/services/portable_temperature_limits.dart';
import '../../domain/use_cases/adjust_base_temperature_use_case.dart';
import '../../domain/use_cases/adjust_boost_offset_use_case.dart';
import '../../domain/use_cases/adjust_super_boost_offset_use_case.dart';
import '../../domain/use_cases/apply_quick_setup_use_case.dart';
import '../navigation/portable_navigator.dart';
import 'portable_session_binding.dart';
import 'portable_tab.dart';

/// The "set it once, then use the button" screen.
class PortableSetupViewModel {
  PortableSetupViewModel({
    PortableSessionBinding? session,
    PortableLadderService? ladderService,
    AdjustBaseTemperatureUseCase? adjustBase,
    AdjustBoostOffsetUseCase? adjustBoost,
    AdjustSuperBoostOffsetUseCase? adjustSuperBoost,
    ApplyQuickSetupUseCase? applyQuickSetup,
    PortableNavigator? navigator,
  }) : _session = session ?? sl<PortableSessionBinding>(),
       _ladderService = ladderService ?? sl<PortableLadderService>(),
       _adjustBase = adjustBase ?? sl<AdjustBaseTemperatureUseCase>(),
       _adjustBoost = adjustBoost ?? sl<AdjustBoostOffsetUseCase>(),
       _adjustSuperBoost =
           adjustSuperBoost ?? sl<AdjustSuperBoostOffsetUseCase>(),
       _applyQuickSetup = applyQuickSetup ?? sl<ApplyQuickSetupUseCase>(),
       _navigator = navigator ?? sl<PortableNavigator>();

  final PortableSessionBinding _session;
  final PortableLadderService _ladderService;
  final AdjustBaseTemperatureUseCase _adjustBase;
  final AdjustBoostOffsetUseCase _adjustBoost;
  final AdjustSuperBoostOffsetUseCase _adjustSuperBoost;
  final ApplyQuickSetupUseCase _applyQuickSetup;
  final PortableNavigator _navigator;

  /// Every quick setup with the ladder it would write.
  late final List<({QuickSetup setup, PortableLadder ladder})> quickSetups = [
    for (final setup in QuickSetup.values)
      (setup: setup, ladder: _ladderService.quickSetupLadder(setup)),
  ];

  /// Ends of the ladder scale in °C.
  int get scaleMinimum => PortableTemperatureLimits.minTemperature;

  int get scaleMaximum => PortableTemperatureLimits.maxTemperature;

  ReadonlySignal<PortableStatus?> get status => _session.status;

  ReadonlySignal<ConnectionStatus> get connectionStatus =>
      _session.connectionStatus;

  ReadonlySignal<String> get deviceName => _session.deviceName;

  ReadonlySignal<bool> get controlsEnabled => _session.controlsEnabled;

  late final Computed<PortableLadder?> ladder = computed(() {
    final status = _session.status.value;
    return status == null ? null : _ladderService.ladder(status);
  });

  /// The quick setup the device matches exactly, if any.
  late final Computed<QuickSetup?> matchingQuickSetup = computed(() {
    final status = _session.status.value;
    return status == null ? null : _ladderService.matchingQuickSetup(status);
  });

  void lowerBase() => _step(() => _adjustBase(-1));

  void raiseBase() => _step(() => _adjustBase(1));

  void lowerBoost() => _step(() => _adjustBoost(-1));

  void raiseBoost() => _step(() => _adjustBoost(1));

  void lowerSuperBoost() => _step(() => _adjustSuperBoost(-1));

  void raiseSuperBoost() => _step(() => _adjustSuperBoost(1));

  Future<void> applyQuickSetup(QuickSetup setup) {
    if (matchingQuickSetup.value == setup) return Future.value();
    _session.tick();
    return _session.write(() async {
      (await _applyQuickSetup(
        setup,
      )).match(_session.showError, (_) => _session.confirmSaved());
    });
  }

  void openSettings() => _navigator.openSettings();

  void selectTab(PortableTab tab) {
    if (tab != PortableTab.setup) _navigator.goToTab(tab);
  }

  void dispose() {
    ladder.dispose();
    matchingQuickSetup.dispose();
    _session.dispose();
  }

  void _step(Future<Either<AppError, Option<int>>> Function() adjust) =>
      unawaited(_session.step(adjust));
}
