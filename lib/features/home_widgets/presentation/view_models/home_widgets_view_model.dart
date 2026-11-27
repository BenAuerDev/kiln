import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../ramps/domain/use_cases/load_ramps_use_case.dart';
import '../../domain/models/portable_widget_snapshot.dart';
import '../../domain/models/ramp_widget_snapshot.dart';
import '../../domain/models/volcano_widget_snapshot.dart';
import '../../domain/use_cases/current_portable_widget_use_case.dart';
import '../../domain/use_cases/current_ramp_widget_use_case.dart';
import '../../domain/use_cases/current_volcano_widget_use_case.dart';
import '../../domain/use_cases/show_portable_widget_use_case.dart';
import '../../domain/use_cases/show_ramp_widget_use_case.dart';
import '../../domain/use_cases/show_volcano_widget_use_case.dart';
import '../../domain/use_cases/listen_to_home_widget_actions_use_case.dart';
import '../extensions/portable_widget_snapshot_x.dart';
import '../extensions/ramp_widget_snapshot_x.dart';
import '../extensions/volcano_widget_snapshot_x.dart';

/// App-level, created once by `KilnApp`: keeps the home-screen widgets
/// (Venty/Veazy, Volcano, ramp) in step with the active device and runs
/// the buttons pressed on them.
///
/// Each widget is live while its kind of device is connected, and shows
/// the last values of this run (or of an earlier one, stored by Android)
/// otherwise. The first show of a run always writes, so a widget left live
/// by an earlier run goes offline until this run connects. Demo devices
/// never reach a widget.
class HomeWidgetsViewModel {
  HomeWidgetsViewModel({
    CurrentPortableWidgetUseCase? currentPortable,
    CurrentVolcanoWidgetUseCase? currentVolcano,
    ShowPortableWidgetUseCase? showPortable,
    ShowVolcanoWidgetUseCase? showVolcano,
    CurrentRampWidgetUseCase? currentRamp,
    ShowRampWidgetUseCase? showRamp,
    LoadRampsUseCase? loadRamps,
    ListenToHomeWidgetActionsUseCase? listenToActions,
    L10nService? l10n,
  }) : _currentPortable = currentPortable ?? sl<CurrentPortableWidgetUseCase>(),
       _currentVolcano = currentVolcano ?? sl<CurrentVolcanoWidgetUseCase>(),
       _showPortable = showPortable ?? sl<ShowPortableWidgetUseCase>(),
       _showVolcano = showVolcano ?? sl<ShowVolcanoWidgetUseCase>(),
       _currentRamp = currentRamp ?? sl<CurrentRampWidgetUseCase>(),
       _showRamp = showRamp ?? sl<ShowRampWidgetUseCase>(),
       _loadRamps = loadRamps ?? sl<LoadRampsUseCase>(),
       _listenToActions =
           listenToActions ?? sl<ListenToHomeWidgetActionsUseCase>(),
       _l10n = l10n ?? sl<L10nService>() {
    _effects
      ..add(effect(_syncPortable))
      ..add(effect(_syncVolcano))
      ..add(effect(_syncRamp));
    _listenToActions(listen: true);
    // The chosen ramp may be one of the user's own, kept across restarts;
    // the widget needs it before the ramp card is ever opened. A failed
    // load leaves Classic; the ramp card reports it.
    unawaited(_loadRamps().then((_) {}));
  }

  final CurrentPortableWidgetUseCase _currentPortable;
  final CurrentVolcanoWidgetUseCase _currentVolcano;
  final ShowPortableWidgetUseCase _showPortable;
  final ShowVolcanoWidgetUseCase _showVolcano;
  final CurrentRampWidgetUseCase _currentRamp;
  final ShowRampWidgetUseCase _showRamp;
  final LoadRampsUseCase _loadRamps;
  final ListenToHomeWidgetActionsUseCase _listenToActions;
  final L10nService _l10n;
  final List<void Function()> _effects = [];

  /// The last snapshots shown in this run, kept while offline so a
  /// language change still reaches the widgets.
  PortableWidgetSnapshot? _lastPortable;
  VolcanoWidgetSnapshot? _lastVolcano;
  RampWidgetSnapshot? _lastRamp;

  /// For the reconnect rule of `HomeWidgetSnapshotService.volcano`.
  VolcanoWidgetSnapshot? _previousVolcano;

  late final Computed<PortableWidgetSnapshot?> _portable = computed(
    _currentPortable.call,
  );

  late final Computed<VolcanoWidgetSnapshot?> _volcano = computed(
    () => _previousVolcano = _currentVolcano(previous: _previousVolcano),
  );

  void _syncPortable() {
    final current = _portable.value;
    // Tracked: a language change re-sends the texts.
    final strings = _l10n.strings;
    untracked(() {
      final shown = _lastPortable = current ?? _lastPortable;
      unawaited(
        _showPortable(
          shown?.content(strings),
          live: current != null,
        ).then((_) {}),
      );
    });
  }

  void _syncVolcano() {
    final current = _volcano.value;
    final strings = _l10n.strings;
    untracked(() {
      final shown = _lastVolcano = current ?? _lastVolcano;
      unawaited(
        _showVolcano(
          shown?.content(strings),
          live: current != null,
        ).then((_) {}),
      );
    });
  }

  late final Computed<RampWidgetSnapshot?> _ramp = computed(_currentRamp.call);

  void _syncRamp() {
    final current = _ramp.value;
    final strings = _l10n.strings;
    untracked(() {
      final shown = _lastRamp = current ?? _lastRamp;
      unawaited(
        _showRamp(shown?.content(strings), live: current != null).then((_) {}),
      );
    });
  }

  void dispose() {
    _listenToActions(listen: false);
    for (final dispose in _effects) {
      dispose();
    }
    _portable.dispose();
    _volcano.dispose();
    _ramp.dispose();
  }
}
