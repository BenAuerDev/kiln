import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/use_cases/disconnect_device_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockConnectionRepository connection;

  setUp(() => connection = MockConnectionRepository());

  test('disconnects', () async {
    when(() => connection.disconnect()).thenAnswer((_) async => right(unit));

    final result = await DisconnectDeviceUseCase(connection: connection)();

    expect(result.isRight(), isTrue);
    verify(() => connection.disconnect()).called(1);
  });

  test('passes errors on', () async {
    when(
      () => connection.disconnect(),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    final result = await DisconnectDeviceUseCase(connection: connection)();

    expect(result.getLeft().toNullable(), isA<TimeoutError>());
  });
}
