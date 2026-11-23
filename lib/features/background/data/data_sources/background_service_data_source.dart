import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Android foreground service (`KilnSessionService`) behind the method
/// channel in `MainActivity`. A no-op elsewhere.
class BackgroundServiceDataSource {
  BackgroundServiceDataSource([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'dev.bespokecode.kiln/background';

  final MethodChannel _channel;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Throws a [PlatformException] (`not_allowed`) when Android refuses to
  /// start a foreground service because kiln is in the background.
  Future<void> start({
    required String title,
    required String text,
    required String sessionChannel,
    required String readyChannel,
  }) => _channel.invokeMethod<void>('start', {
    'title': title,
    'text': text,
    'sessionChannel': sessionChannel,
    'readyChannel': readyChannel,
  });

  Future<void> update({required String title, required String text}) =>
      _channel.invokeMethod<void>('update', {'title': title, 'text': text});

  Future<void> stop() => _channel.invokeMethod<void>('stop');

  Future<void> alert({
    required String title,
    required String text,
    required String sessionChannel,
    required String readyChannel,
  }) => _channel.invokeMethod<void>('alert', {
    'title': title,
    'text': text,
    'sessionChannel': sessionChannel,
    'readyChannel': readyChannel,
  });

  Future<void> cancelAlert() => _channel.invokeMethod<void>('cancelAlert');

  /// `true` when notifications may be shown (always below Android 13).
  Future<bool> requestNotificationPermission() async =>
      await _channel.invokeMethod<bool>('requestNotificationPermission') ??
      false;
}
