import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../models/portable_widget_dto.dart';
import '../models/ramp_widget_dto.dart';
import '../models/volcano_widget_dto.dart';

/// The Android home-screen widgets: their stored values (home_widget's
/// `HomeWidgetPreferences`, one JSON string per widget) and the buttons
/// pressed on them, which the providers forward over
/// [actionsChannelName] while kiln runs. A no-op elsewhere.
class HomeWidgetDataSource {
  HomeWidgetDataSource([MethodChannel? actionsChannel])
    : _actionsChannel =
          actionsChannel ?? const MethodChannel(actionsChannelName);

  static const actionsChannelName = 'dev.bespokecode.kiln/widgets';
  static const portableKey = 'portable';
  static const portableLiveKey = 'portable_live';
  static const volcanoKey = 'volcano';
  static const volcanoLiveKey = 'volcano_live';
  static const rampKey = 'ramp';
  static const rampLiveKey = 'ramp_live';
  static const portableProvider = 'dev.bespokecode.kiln.PortableWidgetProvider';
  static const volcanoProvider = 'dev.bespokecode.kiln.VolcanoWidgetProvider';
  static const rampProvider = 'dev.bespokecode.kiln.RampWidgetProvider';

  final MethodChannel _actionsChannel;
  Future<void> Function(String action)? _actionHandler;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Runs [handler] with the name of every pressed button (`volcanoHeat`,
  /// `rampToggle`, …); `null` stops. Android waits for it to finish and keeps
  /// kiln awake until then.
  void setActionHandler(Future<void> Function(String action)? handler) {
    _actionHandler = handler;
    _actionsChannel.setMethodCallHandler(handler == null ? null : _onCall);
  }

  Future<void> savePortable(PortableWidgetDto dto) =>
      _save(portableKey, jsonEncode(dto.toJson()));

  Future<void> saveVolcano(VolcanoWidgetDto dto) =>
      _save(volcanoKey, jsonEncode(dto.toJson()));

  Future<void> saveRamp(RampWidgetDto dto) =>
      _save(rampKey, jsonEncode(dto.toJson()));

  /// Whether the Venty/Veazy widget may show live values and send its
  /// buttons to kiln.
  Future<void> savePortableLive(bool live) => _save(portableLiveKey, live);

  /// Whether the Volcano widget may show live values and send its buttons
  /// to kiln.
  Future<void> saveVolcanoLive(bool live) => _save(volcanoLiveKey, live);

  /// Whether the ramp widget may show live values and send its button to
  /// kiln.
  Future<void> saveRampLive(bool live) => _save(rampLiveKey, live);

  Future<void> updatePortable() =>
      HomeWidget.updateWidget(qualifiedAndroidName: portableProvider);

  Future<void> updateVolcano() =>
      HomeWidget.updateWidget(qualifiedAndroidName: volcanoProvider);

  Future<void> updateRamp() =>
      HomeWidget.updateWidget(qualifiedAndroidName: rampProvider);

  Future<void> _save<T>(String key, T value) async {
    final saved = await HomeWidget.saveWidgetData<T>(key, value);
    if (saved == false) throw StateError('Widget data "$key" not saved');
  }

  Future<Object?> _onCall(MethodCall call) async {
    final action = call.arguments;
    final handler = _actionHandler;
    if (call.method == 'action' && action is String && handler != null) {
      await handler(action);
    }
    return null;
  }
}
