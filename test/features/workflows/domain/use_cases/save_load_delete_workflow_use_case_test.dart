import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/services/workflow_editing_service.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/use_cases/delete_workflow_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/load_workflows_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/save_workflow_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockWorkflowsRepository repository;
  late SaveWorkflowUseCase save;
  final t0 = DateTime.fromMicrosecondsSinceEpoch(42);

  setUpAll(
    () => registerFallbackValue(const Workflow(id: '', name: '', steps: [])),
  );

  setUp(() {
    repository = MockWorkflowsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => right(unit));
    when(() => repository.delete(any())).thenAnswer((_) async => right(unit));
    when(() => repository.load()).thenAnswer((_) async => right(unit));
    save = SaveWorkflowUseCase(
      repository: repository,
      editing: WorkflowEditingService(),
      clock: () => t0,
    );
  });

  group('save', () {
    test('gives a new workflow an id, trims the name, clamps steps', () async {
      final result = await save(
        const Workflow(
          id: '',
          name: '  Evening  ',
          steps: [HeatStep(260), AirStep(Duration(seconds: 1))],
          heaterOffAtEnd: false,
        ),
      );
      const expected = Workflow(
        id: 'user.42',
        name: 'Evening',
        steps: [HeatStep(230), AirStep(Duration(seconds: 5))],
        heaterOffAtEnd: false,
      );
      expect(result, right<AppError, Option<Workflow>>(some(expected)));
      verify(() => repository.save(expected)).called(1);
    });

    test('keeps the id of an existing workflow', () async {
      final result = await save(
        const Workflow(id: 'user.7', name: 'B', steps: [HeatStep(185)]),
      );
      expect(result.getRight().toNullable()!.toNullable()!.id, 'user.7');
    });

    test('a preset is saved as a new user workflow', () async {
      final preset = WorkflowPresets.all.first.copyWith(name: 'Mine');
      final saved = (await save(preset)).getRight().toNullable()!.toNullable()!;
      expect(saved.id, 'user.42');
      expect(saved.isPreset, isFalse);
    });

    test('cuts long names and too many steps', () async {
      final saved = (await save(
        Workflow(
          id: '',
          name: 'x' * 60,
          steps: List.filled(30, const HeatStep(185)),
        ),
      )).getRight().toNullable()!.toNullable()!;
      expect(saved.name.length, WorkflowEditingService.maxNameLength);
      expect(saved.steps.length, WorkflowEditingService.maxSteps);
    });

    test('no name or no steps saves nothing', () async {
      expect(
        await save(const Workflow(id: '', name: ' ', steps: [HeatStep(185)])),
        right<AppError, Option<Workflow>>(none()),
      );
      expect(
        await save(const Workflow(id: '', name: 'A', steps: [])),
        right<AppError, Option<Workflow>>(none()),
      );
      verifyNever(() => repository.save(any()));
    });

    test('passes a storage error on', () async {
      when(
        () => repository.save(any()),
      ).thenAnswer((_) async => left(const AppError.storage()));
      expect(
        (await save(
          const Workflow(id: '', name: 'A', steps: [HeatStep(185)]),
        )).getLeft().toNullable(),
        isA<StorageError>(),
      );
    });
  });

  test('load and delete pass through', () async {
    await LoadWorkflowsUseCase(repository: repository)();
    await DeleteWorkflowUseCase(repository: repository)('user.1');
    verify(() => repository.load()).called(1);
    verify(() => repository.delete('user.1')).called(1);
  });
}
