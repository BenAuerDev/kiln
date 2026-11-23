import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/ble/ble_error_mapper.dart';
import '../../../../core/ble/ble_scan_hit.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/device_scan_data_source.dart';
import '../models/discovered_device.dart';
import '../services/scan_filter_service.dart';

class ScanRepository {
  ScanRepository({
    DeviceScanDataSource? dataSource,
    ScanFilterService? filter,
    this._scanDuration = const Duration(seconds: 15),
  }) : _dataSource = dataSource ?? sl<DeviceScanDataSource>(),
       _filter = filter ?? sl<ScanFilterService>();

  final DeviceScanDataSource _dataSource;
  final ScanFilterService _filter;
  final Duration _scanDuration;

  final _results = signal<List<DiscoveredDevice>>(const []);
  final _scanning = signal<bool>(false);

  StreamSubscription<List<BleScanHit>>? _subscription;
  Timer? _timer;

  /// S&B devices of the current or last scan, strongest signal first.
  ReadonlySignal<List<DiscoveredDevice>> get results => _results;
  ReadonlySignal<bool> get scanning => _scanning;

  /// Starts a fresh scan that ends by itself after the scan duration.
  /// Completes once the scan is running or has failed to start.
  Future<Either<AppError, Unit>> start() {
    unawaited(_cancel());
    _results.value = const [];
    _scanning.value = true;
    final started = Completer<Either<AppError, Unit>>();
    void complete(Either<AppError, Unit> result) {
      if (!started.isCompleted) started.complete(result);
    }

    _subscription = _dataSource
        .scan(_scanDuration)
        .listen(
          (hits) {
            _results.value = _filter.discoveredFrom(hits);
            complete(right(unit));
          },
          onError: (Object e) {
            unawaited(_cancel());
            complete(left(BleErrorMapper.toAppError(e)));
          },
          onDone: () {
            _timer?.cancel();
            _scanning.value = false;
            complete(right(unit));
          },
        );
    _timer = Timer(_scanDuration, () => unawaited(_cancel()));
    return started.future;
  }

  Future<Either<AppError, Unit>> stop() async {
    final wasScanning = _scanning.value;
    await _cancel();
    if (!wasScanning) return right(unit);
    try {
      await _dataSource.stop();
      return right(unit);
    } catch (e) {
      return left(BleErrorMapper.toAppError(e));
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    _timer = null;
    _scanning.value = false;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}
