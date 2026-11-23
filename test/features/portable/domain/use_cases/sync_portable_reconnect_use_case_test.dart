import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/use_cases/sync_portable_reconnect_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

void main() {
  late MockConnectionRepository connection;
  late SyncPortableReconnectUseCase useCase;

  setUp(() {
    connection = MockConnectionRepository();
    useCase = SyncPortableReconnectUseCase(connection: connection);
  });

  test('a switched-off device is not reconnected after a drop', () {
    useCase(testStatus(heaterMode: HeaterMode.off));

    verify(() => connection.setReconnectAfterDrop(false)).called(1);
  });

  for (final mode in [
    HeaterMode.normal,
    HeaterMode.boost,
    HeaterMode.superboost,
  ]) {
    test('a heating device ($mode) is reconnected after a drop', () {
      useCase(testStatus(heaterMode: mode));

      verify(() => connection.setReconnectAfterDrop(true)).called(1);
    });
  }
}
