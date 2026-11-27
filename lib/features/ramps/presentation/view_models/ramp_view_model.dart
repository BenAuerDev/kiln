import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../../portable/domain/extensions/portable_status_x.dart';
import '../../../portable/domain/repositories/portable_repository.dart';
import '../../domain/models/ramp_profile.dart';
import '../../domain/models/ramp_run.dart';
import '../../domain/repositories/ramp_run_repository.dart';
import '../../domain/repositories/ramps_repository.dart';
import '../../domain/services/ramp_service.dart';
import '../../domain/use_cases/find_ramp_use_case.dart';
import '../../domain/use_cases/load_ramps_use_case.dart';
import '../../domain/use_cases/start_ramp_use_case.dart';
import '../../domain/use_cases/stop_ramp_use_case.dart';
import '../extensions/ramp_profile_x.dart';
import '../extensions/ramp_run_x.dart';
import '../navigation/ramps_navigator.dart';

/// State of the ramp card (Setup tab) and banner (Control tab). Everything
/// but the countdown clock lives in repository signals, so each widget may
/// own an instance. The card offers the presets and the user's own ramps.
class RampViewModel {
  RampViewModel({
    RampRunRepository? runs,
    RampsRepository? userRamps,
    FindRampUseCase? findRamp,
    LoadRampsUseCase? loadRamps,
    RampsNavigator? navigator,
    PortableRepository? portable,
    ConnectionRepository? connection,
    RampService? ramps,
    StartRampUseCase? startRamp,
    StopRampUseCase? stopRamp,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    DateTime Function()? clock,
    this._refresh = const Duration(seconds: 1),
  }) : _runs = runs ?? sl<RampRunRepository>(),
       _userRamps = userRamps ?? sl<RampsRepository>(),
       _findRamp = findRamp ?? sl<FindRampUseCase>(),
       _loadRamps = loadRamps ?? sl<LoadRampsUseCase>(),
       _navigator = navigator ?? sl<RampsNavigator>(),
       _portable = portable ?? sl<PortableRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _ramps = ramps ?? sl<RampService>(),
       _startRamp = startRamp ?? sl<StartRampUseCase>(),
       _stopRamp = stopRamp ?? sl<StopRampUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _clock = clock ?? DateTime.now {
    _now = signal(_clock());
    // The countdown clock only ticks while a ramp runs.
    _disposeTicker = effect(() {
      final running = activeRun.value != null;
      untracked(() {
        _timer?.cancel();
        _timer = running
            ? Timer.periodic(_refresh, (_) => _now.value = _clock())
            : null;
        if (running) _now.value = _clock();
      });
    });
    unawaited(_load());
  }

  final RampRunRepository _runs;
  final RampsRepository _userRamps;
  final FindRampUseCase _findRamp;
  final LoadRampsUseCase _loadRamps;
  final RampsNavigator _navigator;
  final PortableRepository _portable;
  final ConnectionRepository _connection;
  final RampService _ramps;
  final StartRampUseCase _startRamp;
  final StopRampUseCase _stopRamp;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final DateTime Function() _clock;
  final Duration _refresh;
  late final Signal<DateTime> _now;
  late final void Function() _disposeTicker;
  Timer? _timer;

  List<RampProfile> get presets => RampService.presets;

  /// The user's own ramps, in the order they were made.
  ReadonlySignal<List<RampProfile>> get userRamps => _userRamps.ramps;

  /// The running ramp as it started (even if edited or deleted since);
  /// otherwise the chosen ramp, or the default preset once the chosen one
  /// was deleted.
  late final Computed<RampProfile> selected = computed(() {
    final run = activeRun.value;
    if (run != null) return run.profile;
    return _findRamp(_runs.selectedId.value).toNullable() ??
        RampService.defaultPreset;
  });

  /// The presets, then the user's ramps: the tiles of the ramp card.
  late final Computed<List<RampProfile>> options = computed(
    () => [...presets, ...userRamps.value],
  );

  /// Index of the chosen ramp in [options].
  late final Computed<int?> selectedIndex = computed(() {
    final index = options.value.indexWhere((p) => p.id == selected.value.id);
    return index < 0 ? null : index;
  });

  /// `+5° every 2 min · 8 min` for the chosen ramp.
  late final Computed<String> selectedSummary = computed(() {
    final profile = selected.value;
    return profile.summary(_l10n.strings, _ramps.duration(profile));
  });

  /// The running ramp, `null` otherwise.
  late final Computed<RampRun?> activeRun = computed(() {
    final run = _runs.run.value;
    return run != null && run.isActive ? run : null;
  });

  late final Computed<bool> boosting = computed(
    () => _portable.status.value?.boostActive ?? false,
  );

  late final Computed<bool> canStart = computed(
    () =>
        _portable.status.value != null &&
        !boosting.value &&
        activeRun.value == null,
  );

  /// `Now 185° · 190° in 0:42`, ticking every second; empty without a
  /// running or finished ramp of the connected device's current session.
  late final Computed<String> statusLine = computed(() {
    final run = _runs.run.value;
    if (run == null ||
        !_portable.sessionActive.value ||
        !_ramps.isCurrent(
          run,
          deviceId: _connection.activeDeviceId.value,
          session: _portable.sessionNumber.value,
          baseCelsius: _portable.status.value?.targetTemperature,
        )) {
      return '';
    }
    return run.statusLine(_l10n.strings, _now.value);
  });

  String nameOf(RampProfile profile) => profile.displayName(_l10n.strings);

  String rangeOf(RampProfile profile) => profile.range(_l10n.strings);

  /// Chooses the ramp at [index] of [options].
  void select(int index) {
    final all = options.value;
    if (index < 0 || index >= all.length) return;
    selectRamp(all[index].id);
  }

  /// Chooses the preset or user ramp [id]; not while a ramp runs.
  void selectRamp(String id) {
    if (activeRun.value != null || id == _runs.selectedId.value) return;
    unawaited(_haptics.tick());
    _runs.select(id);
  }

  /// A new ramp, starting with the chosen ramp's values.
  void newRamp() => _navigator.openEditor(from: selected.value.id);

  void edit(String id) => _navigator.openEditor(id: id);

  Future<void> start() async {
    unawaited(_haptics.tick());
    (await _startRamp(selected.value)).match(_showError, (_) {
      unawaited(_haptics.success());
    });
  }

  Future<void> stop() async {
    unawaited(_haptics.tick());
    (await _stopRamp()).match(_showError, (_) {});
  }

  Future<void> _load() async {
    (await _loadRamps()).match(_showError, (_) {});
  }

  void _showError(AppError error) {
    unawaited(_haptics.warning());
    _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
  }

  void dispose() {
    _disposeTicker();
    _timer?.cancel();
    _now.dispose();
    selected.dispose();
    options.dispose();
    selectedIndex.dispose();
    selectedSummary.dispose();
    activeRun.dispose();
    boosting.dispose();
    canStart.dispose();
    statusLine.dispose();
  }
}
