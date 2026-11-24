import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/home_widget_data_source.dart';
import '../../data/models/portable_widget_dto.dart';
import '../../data/models/volcano_widget_dto.dart';
import '../models/home_widget_action.dart';
import '../models/portable_widget_content.dart';
import '../models/volcano_widget_content.dart';

/// What the home-screen widgets show, and the buttons pressed on them.
/// Unchanged content is not sent again. Writes run one after another.
class HomeWidgetsRepository {
  HomeWidgetsRepository({HomeWidgetDataSource? dataSource})
    : _dataSource = dataSource ?? sl<HomeWidgetDataSource>() {
    _portableSlot = _Slot(
      _portable,
      save: (content) => _dataSource.savePortable(_portableDto(content)),
      saveLive: _dataSource.savePortableLive,
      update: _dataSource.updatePortable,
    );
    _volcanoSlot = _Slot(
      _volcano,
      save: (content) => _dataSource.saveVolcano(_volcanoDto(content)),
      saveLive: _dataSource.saveVolcanoLive,
      update: _dataSource.updateVolcano,
    );
  }

  final HomeWidgetDataSource _dataSource;

  final _portable = signal<PortableWidgetContent?>(null);
  final _volcano = signal<VolcanoWidgetContent?>(null);
  late final _Slot<PortableWidgetContent> _portableSlot;
  late final _Slot<VolcanoWidgetContent> _volcanoSlot;
  Future<void> _queue = Future.value();

  /// The last content sent in this run of kiln.
  ReadonlySignal<PortableWidgetContent?> get portable => _portable;
  ReadonlySignal<VolcanoWidgetContent?> get volcano => _volcano;

  /// Runs [handler] for every button pressed on a widget (unknown ones are
  /// dropped); `null` stops.
  void setActionHandler(Future<void> Function(HomeWidgetAction)? handler) =>
      _dataSource.setActionHandler(
        handler == null
            ? null
            : (name) async {
                final action = HomeWidgetAction.values
                    .where((action) => action.name == name)
                    .firstOrNull;
                if (action != null) await handler(action);
              },
      );

  /// Shows [content] on the Venty/Veazy widget, live or (when [live] is
  /// off) as last known values. See [showVolcano].
  Future<Either<AppError, Unit>> showPortable(
    PortableWidgetContent? content, {
    required bool live,
  }) => _show(_portableSlot, content, live: live);

  /// Shows [content] on the Volcano widget, live or offline. Without
  /// content it can only be offline. The first call of a run always writes
  /// the live flag, so a widget left live by an earlier run goes offline.
  Future<Either<AppError, Unit>> showVolcano(
    VolcanoWidgetContent? content, {
    required bool live,
  }) => _show(_volcanoSlot, content, live: live);

  Future<Either<AppError, Unit>> _show<C>(
    _Slot<C> slot,
    C? content, {
    required bool live,
  }) {
    final result = _queue
        .then((_) async {
          if (!_dataSource.isSupported) return right<AppError, Unit>(unit);
          await slot.show(content, live: live && content != null);
          return right<AppError, Unit>(unit);
        })
        .catchError(
          (Object _) => left<AppError, Unit>(const AppError.storage()),
        );
    _queue = result.then((_) {});
    return result;
  }

  static PortableWidgetDto _portableDto(PortableWidgetContent content) =>
      PortableWidgetDto(
        glyph: content.glyph,
        name: content.name,
        battery: content.battery,
        batteryLevel: content.batteryLevel,
        ringDescription: content.ringDescription,
        status: content.status,
        statusAccent: content.statusAccent,
        baseLabel: content.baseLabel,
        base: content.base,
        boostLabel: content.boostLabel,
        boost: content.boost,
        superLabel: content.superLabel,
        superBoost: content.superBoost,
        basePosition: content.basePosition,
        boostPosition: content.boostPosition,
        superBoostPosition: content.superBoostPosition,
        ladderDescription: content.ladderDescription,
        heatLabel: content.heatLabel,
        heatActive: content.heatActive,
        boostButtonLabel: content.boostButtonLabel,
        boostActive: content.boostActive,
        offlineStatus: content.offlineStatus,
        offlineHeatLabel: content.offlineHeatLabel,
        offlineBoostLabel: content.offlineBoostLabel,
        accent: content.accent,
        accentText: content.accentText,
        onAccent: content.onAccent,
        gradientStart: content.gradientStart,
        gradientEnd: content.gradientEnd,
      );

  static VolcanoWidgetDto _volcanoDto(VolcanoWidgetContent content) =>
      VolcanoWidgetDto(
        name: content.name,
        temperature: content.temperature,
        status: content.status,
        statusAccent: content.statusAccent,
        progress: content.progress,
        gaugeDescription: content.gaugeDescription,
        heatLabel: content.heatLabel,
        heatActive: content.heatActive,
        airLabel: content.airLabel,
        airActive: content.airActive,
        offlineTemperature: content.offlineTemperature,
        offlineStatus: content.offlineStatus,
        offlineHeatLabel: content.offlineHeatLabel,
        offlineAirLabel: content.offlineAirLabel,
        accent: content.accent,
        accentText: content.accentText,
        onAccent: content.onAccent,
        gradientStart: content.gradientStart,
        gradientEnd: content.gradientEnd,
      );
}

/// One widget: its stored content and live flag, written only when they
/// change.
class _Slot<C> {
  _Slot(
    this._content, {
    required this.save,
    required this.saveLive,
    required this.update,
  });

  final Signal<C?> _content;
  final Future<void> Function(C content) save;
  final Future<void> Function(bool live) saveLive;
  final Future<void> Function() update;

  /// The stored live flag; `null` while unknown (at start, and after a
  /// failed write), so the next show writes it whatever it is.
  bool? _live;

  Future<void> show(C? content, {required bool live}) async {
    final changed = content != null && content != _content.value;
    if (!changed && live == _live) return;
    try {
      if (changed) await save(content);
      if (live != _live) await saveLive(live);
      await update();
    } catch (_) {
      // Some of it may have been stored.
      _live = null;
      _content.value = null;
      rethrow;
    }
    if (changed) _content.value = content;
    _live = live;
  }
}
