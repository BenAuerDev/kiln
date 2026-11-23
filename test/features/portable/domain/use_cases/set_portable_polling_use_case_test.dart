import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/domain/use_cases/set_portable_polling_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late SetPortablePollingUseCase useCase;

  setUp(() {
    repository = MockPortableRepository();
    useCase = SetPortablePollingUseCase(repository: repository);
  });

  test('active resumes polling', () {
    useCase(active: true);

    verify(() => repository.resumePolling()).called(1);
    verifyNever(() => repository.pausePolling());
  });

  test('inactive pauses polling', () {
    useCase(active: false);

    verify(() => repository.pausePolling()).called(1);
    verifyNever(() => repository.resumePolling());
  });
}
