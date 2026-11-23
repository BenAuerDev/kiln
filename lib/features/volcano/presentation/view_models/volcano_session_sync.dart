import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/connection_status.dart';
import '../../../devices/domain/repositories/connection_repository.dart';
import '../../domain/repositories/volcano_repository.dart';
import '../../domain/use_cases/start_volcano_session_use_case.dart';
import '../../domain/use_cases/stop_volcano_session_use_case.dart';

/// Keeps the Volcano session running while the device is connected, on any
/// Volcano screen. [onError] gets start errors worth showing (not the
/// `notConnected` of a start superseded by a newer connection change). Each
/// view model owns one and disposes it.
class VolcanoSessionSync {
  VolcanoSessionSync({
    ConnectionRepository? connection,
    VolcanoRepository? repository,
    StartVolcanoSessionUseCase? startSession,
    StopVolcanoSessionUseCase? stopSession,
    this._onError,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _repository = repository ?? sl<VolcanoRepository>(),
       _startSession = startSession ?? sl<StartVolcanoSessionUseCase>(),
       _stopSession = stopSession ?? sl<StopVolcanoSessionUseCase>() {
    _dispose = effect(_sync);
  }

  final ConnectionRepository _connection;
  final VolcanoRepository _repository;
  final StartVolcanoSessionUseCase _startSession;
  final StopVolcanoSessionUseCase _stopSession;
  final void Function(AppError error)? _onError;
  late final void Function() _dispose;

  void _sync() {
    final deviceId = _connection.activeDeviceId.value;
    final connected = _connection.status.value == ConnectionStatus.connected;
    untracked(() {
      if (connected && deviceId != null) {
        unawaited(_start(deviceId));
      } else if (_repository.sessionActive.value) {
        unawaited(_stopSession().then((_) {}));
      }
    });
  }

  Future<void> _start(String deviceId) async {
    (await _startSession(deviceId)).match((error) {
      if (error is! NotConnectedError) _onError?.call(error);
    }, (_) {});
  }

  void dispose() => _dispose();
}
