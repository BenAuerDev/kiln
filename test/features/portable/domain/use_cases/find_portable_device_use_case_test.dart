import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/use_cases/find_portable_device_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/portable_fixtures.dart';

void main() {
  late MockPortableRepository repository;
  late FindPortableDeviceUseCase useCase;

  void givenStatus(PortableStatus? status) =>
      when(() => repository.status).thenReturn(signal(status));

  setUp(() {
    repository = MockPortableRepository();
    useCase = FindPortableDeviceUseCase(repository: repository);
  });

  test('asks the device to make itself known', () async {
    givenStatus(testStatus());
    when(() => repository.findDevice()).thenAnswer((_) async => right(unit));

    expect((await useCase()).isRight(), isTrue);
    verify(() => repository.findDevice()).called(1);
  });

  test('passes errors through', () async {
    givenStatus(testStatus());
    when(
      () => repository.findDevice(),
    ).thenAnswer((_) async => left(const AppError.connectionLost()));

    expect(
      (await useCase()).getLeft().toNullable(),
      isA<ConnectionLostError>(),
    );
  });

  test('returns notConnected without status', () async {
    givenStatus(null);

    expect((await useCase()).getLeft().toNullable(), isA<NotConnectedError>());
    verifyNever(() => repository.findDevice());
  });
}
