import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/known_devices_data_source.dart';
import '../../data/models/known_device_dto.dart';
import '../models/device_finish.dart';
import '../models/device_model.dart';
import '../models/finish_preference.dart';
import '../models/known_device.dart';
import 'connection_repository.dart';

class KnownDevicesRepository {
  KnownDevicesRepository({
    KnownDevicesDataSource? dataSource,
    ConnectionRepository? connection,
  }) : _dataSource = dataSource ?? sl<KnownDevicesDataSource>(),
       _connectionOverride = connection;

  final KnownDevicesDataSource _dataSource;
  final ConnectionRepository? _connectionOverride;

  late final ConnectionRepository _connection =
      _connectionOverride ?? sl<ConnectionRepository>();

  final _devices = signal<List<KnownDevice>>(const []);
  final _lastDeviceId = signal<String?>(null);

  late final Computed<KnownDevice?> _activeDevice = computed(() {
    final id = _connection.activeDeviceId.value;
    if (id == null) return null;
    return _devices.value.where((d) => d.id == id).firstOrNull;
  });

  ReadonlySignal<List<KnownDevice>> get devices => _devices;

  /// The device kiln reconnects to on start and resume.
  ReadonlySignal<String?> get lastDeviceId => _lastDeviceId;

  /// The known device behind `ConnectionRepository.activeDeviceId`. `null`
  /// while nothing is active, and for a new device until it has been saved.
  ReadonlySignal<KnownDevice?> get activeDevice => _activeDevice;

  KnownDevice? byId(String id) =>
      _devices.value.where((d) => d.id == id).firstOrNull;

  /// Entries this version cannot read (for example an unknown model name)
  /// are skipped instead of failing the whole list.
  Future<Either<AppError, Unit>> load() async {
    try {
      final stored = await _dataSource.readAll();
      _devices.value = List.unmodifiable(stored.map(_toDomainOrNull).nonNulls);
      _lastDeviceId.value = await _dataSource.readLastDeviceId();
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  /// Inserts [device] or replaces the entry with the same id in place.
  Future<Either<AppError, Unit>> save(KnownDevice device) {
    final current = _devices.value;
    final exists = current.any((d) => d.id == device.id);
    return _persist(
      exists
          ? [for (final d in current) d.id == device.id ? device : d]
          : [...current, device],
    );
  }

  Future<Either<AppError, Unit>> remove(String id) async {
    final result = await _persist(
      _devices.value.where((d) => d.id != id).toList(),
    );
    if (result.isLeft() || _lastDeviceId.value != id) return result;
    return setLastDeviceId(null);
  }

  Future<Either<AppError, Unit>> setLastDeviceId(String? id) async {
    try {
      await _dataSource.writeLastDeviceId(id);
      _lastDeviceId.value = id;
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  Future<Either<AppError, Unit>> _persist(List<KnownDevice> devices) async {
    try {
      await _dataSource.writeAll(devices.map(_toDto).toList());
      _devices.value = List.unmodifiable(devices);
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  KnownDevice? _toDomainOrNull(KnownDeviceDto dto) {
    final model = DeviceModel.values.asNameMap()[dto.model];
    if (model == null) return null;
    return KnownDevice(
      id: dto.id,
      name: dto.name,
      model: model,
      finishPreference: switch (DeviceFinish.values.asNameMap()[dto.finish]) {
        final DeviceFinish finish => FixedFinish(finish),
        null => const MatchDevice(),
      },
      detectedFinish: DeviceFinish.values.asNameMap()[dto.detectedFinish],
      lastConnectedAt: dto.lastConnectedAt == null
          ? null
          : DateTime.tryParse(dto.lastConnectedAt!),
    );
  }

  KnownDeviceDto _toDto(KnownDevice device) => KnownDeviceDto(
    id: device.id,
    name: device.name,
    model: device.model.name,
    finish: switch (device.finishPreference) {
      MatchDevice() => 'match',
      FixedFinish(:final finish) => finish.name,
    },
    detectedFinish: device.detectedFinish?.name,
    lastConnectedAt: device.lastConnectedAt?.toIso8601String(),
  );
}
