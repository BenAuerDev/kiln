import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/background_service_data_source.dart';
import '../models/background_notice.dart';

/// Whether the background service runs and what its notification shows.
/// Asks for the notification permission once, the first time it starts.
class BackgroundServiceRepository {
  BackgroundServiceRepository({BackgroundServiceDataSource? dataSource})
    : _dataSource = dataSource ?? sl<BackgroundServiceDataSource>();

  final BackgroundServiceDataSource _dataSource;

  final _running = signal<bool>(false);
  BackgroundNotice? _shown;
  bool _permissionAsked = false;
  Future<void> _queue = Future.value();

  ReadonlySignal<bool> get running => _running;

  bool get isSupported => _dataSource.isSupported;

  /// Starts the service with [notice], or updates its notification. An
  /// unchanged notice is not sent again. Show and hide run one after
  /// another, so a hide during a start (waiting for the permission dialog)
  /// is not lost.
  Future<Either<AppError, Unit>> show(BackgroundNotice notice) =>
      _serialized(() => _show(notice));

  Future<Either<AppError, Unit>> hide() => _serialized(_hide);

  Future<T> _serialized<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Either<AppError, Unit>> _show(BackgroundNotice notice) async {
    if (!isSupported) return right(unit);
    try {
      if (!_running.value) {
        if (!_permissionAsked) {
          _permissionAsked = true;
          // Without the permission the service still runs; Android only
          // hides its notification.
          await _dataSource.requestNotificationPermission();
        }
        await _dataSource.start(
          title: notice.title,
          text: notice.text,
          sessionChannel: notice.sessionChannel,
          readyChannel: notice.readyChannel,
        );
        _running.value = true;
      } else if (notice != _shown) {
        await _dataSource.update(title: notice.title, text: notice.text);
      }
      _shown = notice;
      return right(unit);
    } catch (e) {
      return left(AppError.unknown(e));
    }
  }

  Future<Either<AppError, Unit>> _hide() async {
    if (!_running.value) return right(unit);
    try {
      await _dataSource.stop();
      _running.value = false;
      _shown = null;
      return right(unit);
    } catch (e) {
      return left(AppError.unknown(e));
    }
  }

  /// Stops a service left over from an earlier run of kiln (its Dart side
  /// is gone, so nothing would ever stop it otherwise).
  Future<Either<AppError, Unit>> reset() => _serialized(() async {
    if (!isSupported) return right(unit);
    try {
      await _dataSource.stop();
      _running.value = false;
      _shown = null;
      return right(unit);
    } catch (e) {
      return left(AppError.unknown(e));
    }
  });

  Future<Either<AppError, Unit>> dismissAlert() async {
    if (!isSupported) return right(unit);
    try {
      await _dataSource.cancelAlert();
      return right(unit);
    } catch (e) {
      return left(AppError.unknown(e));
    }
  }

  Future<Either<AppError, Unit>> alert(BackgroundNotice notice) async {
    if (!isSupported) return right(unit);
    try {
      await _dataSource.alert(
        title: notice.title,
        text: notice.text,
        sessionChannel: notice.sessionChannel,
        readyChannel: notice.readyChannel,
      );
      return right(unit);
    } catch (e) {
      return left(AppError.unknown(e));
    }
  }
}
