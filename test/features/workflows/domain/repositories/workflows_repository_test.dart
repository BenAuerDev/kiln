import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/workflows/data/models/workflow_dto.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/repositories/workflows_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_editing_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockWorkflowsDataSource dataSource;
  late WorkflowsRepository repository;

  const evening = Workflow(
    id: 'user.1',
    name: 'Evening',
    steps: [
      HeatStep(185),
      HoldStep(Duration(seconds: 30)),
      AirStep(Duration(seconds: 45)),
    ],
  );

  setUpAll(() => registerFallbackValue(<WorkflowDto>[]));

  setUp(() {
    dataSource = MockWorkflowsDataSource();
    when(() => dataSource.writeAll(any())).thenAnswer((_) async {});
    repository = WorkflowsRepository(
      dataSource: dataSource,
      editing: WorkflowEditingService(),
    );
  });

  test('save writes every step type and load reads them back', () async {
    await repository.save(evening);
    final written =
        verify(() => dataSource.writeAll(captureAny())).captured.single
            as List<WorkflowDto>;
    expect(written.single.steps.map((s) => (s.type, s.value)), [
      ('heat', 185),
      ('hold', 30),
      ('air', 45),
    ]);

    when(() => dataSource.readAll()).thenAnswer((_) async => written);
    final fresh = WorkflowsRepository(
      dataSource: dataSource,
      editing: WorkflowEditingService(),
    );
    expect((await fresh.load()).isRight(), isTrue);
    expect(fresh.workflows.value, [evening]);
    expect(fresh.byId('user.1'), evening);
  });

  test(
    'load skips workflows with unknown or no steps, and runs once',
    () async {
      when(() => dataSource.readAll()).thenAnswer(
        (_) async => const [
          WorkflowDto(
            id: 'a',
            name: 'A',
            heaterOffAtEnd: true,
            steps: [WorkflowStepDto(type: 'dance', value: 1)],
          ),
          WorkflowDto(id: 'b', name: 'B', heaterOffAtEnd: true, steps: []),
        ],
      );
      await repository.load();
      await repository.load();
      expect(repository.workflows.value, isEmpty);
      verify(() => dataSource.readAll()).called(1);
    },
  );

  test('load brings stored steps into the limits', () async {
    when(() => dataSource.readAll()).thenAnswer(
      (_) async => const [
        WorkflowDto(
          id: 'x',
          name: 'X',
          heaterOffAtEnd: true,
          steps: [
            WorkflowStepDto(type: 'heat', value: 400),
            WorkflowStepDto(type: 'air', value: 9999),
          ],
        ),
      ],
    );
    await repository.load();
    expect(repository.workflows.value.single.steps, [
      const HeatStep(230),
      const AirStep(Duration(minutes: 10)),
    ]);
  });

  test('save replaces in place, delete removes', () async {
    await repository.save(evening);
    await repository.save(
      const Workflow(id: 'user.2', name: 'B', steps: [HeatStep(200)]),
    );
    await repository.save(evening.copyWith(name: 'Late'));
    expect(repository.workflows.value.map((w) => w.name), ['Late', 'B']);
    await repository.delete('user.1');
    expect(repository.workflows.value.map((w) => w.id), ['user.2']);
  });

  test('storage errors come back as AppError and keep the list', () async {
    when(() => dataSource.readAll()).thenThrow(Exception('disk'));
    expect(
      (await repository.load()).getLeft().toNullable(),
      isA<StorageError>(),
    );
    when(() => dataSource.writeAll(any())).thenThrow(Exception('disk'));
    expect(
      (await repository.save(evening)).getLeft().toNullable(),
      isA<StorageError>(),
    );
    expect(repository.workflows.value, isEmpty);
  });
}
