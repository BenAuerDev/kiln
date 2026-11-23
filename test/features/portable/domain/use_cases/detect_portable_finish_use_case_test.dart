import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/services/finish_detection_service.dart';
import 'package:kiln/features/devices/domain/use_cases/set_detected_finish_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/detect_portable_finish_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';

class MockSetDetectedFinishUseCase extends Mock
    implements SetDetectedFinishUseCase {}

void main() {
  late MockPortableRepository repository;
  late MockSetDetectedFinishUseCase setDetectedFinish;
  late DetectPortableFinishUseCase useCase;

  setUpAll(() => registerFallbackValue(DeviceFinish.ember));

  setUp(() {
    repository = MockPortableRepository();
    setDetectedFinish = MockSetDetectedFinishUseCase();
    useCase = DetectPortableFinishUseCase(
      repository: repository,
      detection: const FinishDetectionService(),
      setDetectedFinish: setDetectedFinish,
    );
    when(
      () => setDetectedFinish(any(), any()),
    ).thenAnswer((_) async => right(unit));
  });

  test('records the colour a Veazy reports', () async {
    when(
      () => repository.readColorIndex(),
    ).thenAnswer((_) async => right(some(3)));

    final result = await useCase('id', DeviceModel.veazy);

    expect(result.getRight().toNullable()?.toNullable(), DeviceFinish.pink);
    verify(() => setDetectedFinish('id', DeviceFinish.pink)).called(1);
  });

  test('does not read anything on a Venty', () async {
    final result = await useCase('id', DeviceModel.venty);

    expect(result.getRight().toNullable()?.isNone(), isTrue);
    verifyNever(() => repository.readColorIndex());
    verifyNever(() => setDetectedFinish(any(), any()));
  });

  test('records nothing when the reply has no colour byte', () async {
    when(
      () => repository.readColorIndex(),
    ).thenAnswer((_) async => right(none()));

    final result = await useCase('id', DeviceModel.veazy);

    expect(result.getRight().toNullable()?.isNone(), isTrue);
    verifyNever(() => setDetectedFinish(any(), any()));
  });

  test('passes read errors through without recording', () async {
    when(
      () => repository.readColorIndex(),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    final result = await useCase('id', DeviceModel.veazy);

    expect(result.getLeft().toNullable(), isA<TimeoutError>());
    verifyNever(() => setDetectedFinish(any(), any()));
  });

  test('passes storage errors through', () async {
    when(
      () => repository.readColorIndex(),
    ).thenAnswer((_) async => right(some(2)));
    when(
      () => setDetectedFinish('id', DeviceFinish.blue),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase('id', DeviceModel.veazy);

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
