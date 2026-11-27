import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../data/data_sources/workflows_data_source.dart';
import '../../data/models/workflow_dto.dart';
import '../models/workflow.dart';
import '../models/workflow_step.dart';
import '../services/workflow_editing_service.dart';

/// The user's own workflows (presets live in `WorkflowPresets`).
class WorkflowsRepository {
  WorkflowsRepository({
    WorkflowsDataSource? dataSource,
    WorkflowEditingService? editing,
  }) : _dataSource = dataSource ?? sl<WorkflowsDataSource>(),
       _editing = editing ?? sl<WorkflowEditingService>();

  final WorkflowsDataSource _dataSource;
  final WorkflowEditingService _editing;

  final _workflows = signal<List<Workflow>>(const []);
  bool _loaded = false;

  ReadonlySignal<List<Workflow>> get workflows => _workflows;

  Workflow? byId(String id) =>
      _workflows.value.where((w) => w.id == id).firstOrNull;

  /// Reads once; later calls return right away.
  Future<Either<AppError, Unit>> load() async {
    if (_loaded) return right(unit);
    try {
      final stored = await _dataSource.readAll();
      _workflows.value = List.unmodifiable(
        stored.map(_toDomainOrNull).nonNulls,
      );
      _loaded = true;
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  /// Inserts [workflow] or replaces the one with the same id in place.
  Future<Either<AppError, Unit>> save(Workflow workflow) => _afterLoad(() {
    final current = _workflows.value;
    final exists = current.any((w) => w.id == workflow.id);
    return _persist(
      exists
          ? [for (final w in current) w.id == workflow.id ? workflow : w]
          : [...current, workflow],
    );
  });

  Future<Either<AppError, Unit>> delete(String id) => _afterLoad(
    () => _persist(_workflows.value.where((w) => w.id != id).toList()),
  );

  /// Writes only on top of what is stored: without a successful load, a
  /// write would replace every stored workflow with the few in memory.
  Future<Either<AppError, Unit>> _afterLoad(
    Future<Either<AppError, Unit>> Function() write,
  ) async {
    final loaded = await load();
    return loaded.isLeft() ? loaded : write();
  }

  Future<Either<AppError, Unit>> _persist(List<Workflow> workflows) async {
    try {
      await _dataSource.writeAll(workflows.map(_toDto).toList());
      _workflows.value = List.unmodifiable(workflows);
      return right(unit);
    } catch (_) {
      return left(const AppError.storage());
    }
  }

  Workflow? _toDomainOrNull(WorkflowDto dto) {
    final steps = <WorkflowStep>[];
    for (final step in dto.steps) {
      final mapped = switch (step.type) {
        'heat' => HeatStep(step.value),
        'hold' => HoldStep(Duration(seconds: step.value)),
        'air' => AirStep(Duration(seconds: step.value)),
        _ => null,
      };
      if (mapped == null) return null;
      steps.add(_editing.normalise(mapped));
    }
    if (steps.isEmpty) return null;
    return Workflow(
      id: dto.id,
      name: dto.name,
      steps: List.unmodifiable(steps),
      heaterOffAtEnd: dto.heaterOffAtEnd,
    );
  }

  WorkflowDto _toDto(Workflow workflow) => WorkflowDto(
    id: workflow.id,
    name: workflow.name,
    heaterOffAtEnd: workflow.heaterOffAtEnd,
    steps: [
      for (final step in workflow.steps)
        switch (step) {
          HeatStep(:final celsius) => WorkflowStepDto(
            type: 'heat',
            value: celsius,
          ),
          HoldStep(:final duration) => WorkflowStepDto(
            type: 'hold',
            value: duration.inSeconds,
          ),
          AirStep(:final duration) => WorkflowStepDto(
            type: 'air',
            value: duration.inSeconds,
          ),
        },
    ],
  );
}
