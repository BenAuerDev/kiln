import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';
import 'package:kiln/features/workflows/domain/use_cases/find_workflow_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockWorkflowsRepository repository;
  late FindWorkflowUseCase find;

  const mine = Workflow(id: 'user.1', name: 'Mine', steps: [HeatStep(185)]);

  setUp(() {
    repository = MockWorkflowsRepository();
    when(() => repository.byId(any())).thenReturn(null);
    when(() => repository.byId('user.1')).thenReturn(mine);
    find = FindWorkflowUseCase(repository: repository);
  });

  test('finds a user workflow', () {
    expect(find('user.1'), const Some(mine));
  });

  test('finds a preset', () {
    final preset = WorkflowPresets.all.last;
    expect(find(preset.id), Some(preset));
  });

  test('a deleted or unknown id is none', () {
    expect(find('user.gone'), const None());
  });
}
