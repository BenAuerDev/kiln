import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/ramps_data_source.dart';
import '../../data/models/ramp_dto.dart';
import '../models/ramp_profile.dart';
import '../services/ramp_editing_service.dart';

/// The user's own ramps (presets live in `RampService`).
class RampsRepository {
  RampsRepository({RampsDataSource? dataSource, RampEditingService? editing})
    : _dataSource = dataSource ?? sl<RampsDataSource>(),
      _editing = editing ?? sl<RampEditingService>();

  final RampsDataSource _dataSource;
  final RampEditingService _editing;

  final _ramps = signal<List<RampProfile>>(const []);
  bool _loaded = false;

  ReadonlySignal<List<RampProfile>> get ramps => _ramps;

  RampProfile? byId(String id) =>
      _ramps.value.where((r) => r.id == id).firstOrNull;

  /// Reads once; later calls return right away. Entries with an id seen
  /// before are dropped.
  Future<Either<AppError, Unit>> load() async {
    if (_loaded) return right(unit);
    try {
      final stored = await _dataSource.readAll();
      final ids = <String>{};
      _ramps.value = List.unmodifiable(
        stored.where((dto) => ids.add(dto.id)).map(_toDomain),
      );
      _loaded = true;
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  /// Inserts [ramp] or replaces the one with the same id in place.
  Future<Either<AppError, Unit>> save(RampProfile ramp) => _afterLoad(() {
    final current = _ramps.value;
    final exists = current.any((r) => r.id == ramp.id);
    return _persist(
      exists
          ? [for (final r in current) r.id == ramp.id ? ramp : r]
          : [...current, ramp],
    );
  });

  Future<Either<AppError, Unit>> delete(String id) => _afterLoad(
    () => _persist(_ramps.value.where((r) => r.id != id).toList()),
  );

  /// Writes only on top of what is stored: without a successful load, a
  /// write would replace every stored ramp with the few in memory.
  Future<Either<AppError, Unit>> _afterLoad(
    Future<Either<AppError, Unit>> Function() write,
  ) async {
    final loaded = await load();
    return loaded.isLeft() ? loaded : write();
  }

  Future<Either<AppError, Unit>> _persist(List<RampProfile> ramps) async {
    try {
      await _dataSource.writeAll(ramps.map(_toDto).toList());
      _ramps.value = List.unmodifiable(ramps);
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  RampProfile _toDomain(RampDto dto) => _editing.normalise(
    RampProfile(
      id: dto.id,
      name: dto.name,
      startCelsius: dto.startCelsius,
      endCelsius: dto.endCelsius,
      stepCelsius: dto.stepCelsius,
      interval: Duration(seconds: dto.intervalSeconds),
    ),
  );

  RampDto _toDto(RampProfile ramp) => RampDto(
    id: ramp.id,
    name: ramp.name,
    startCelsius: ramp.startCelsius,
    endCelsius: ramp.endCelsius,
    stepCelsius: ramp.stepCelsius,
    intervalSeconds: ramp.interval.inSeconds,
  );
}
