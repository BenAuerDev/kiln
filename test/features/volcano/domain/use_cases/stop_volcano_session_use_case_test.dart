import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/volcano/domain/use_cases/stop_volcano_session_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  test('stops the session', () async {
    final repository = MockVolcanoRepository();
    when(repository.stopSession).thenAnswer((_) async => right(unit));

    final result = await StopVolcanoSessionUseCase(repository: repository)();

    expect(result, right(unit));
    verify(repository.stopSession).called(1);
  });
}
