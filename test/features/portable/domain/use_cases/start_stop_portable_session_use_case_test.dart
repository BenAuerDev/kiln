import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/portable/domain/use_cases/detect_portable_finish_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/start_portable_session_use_case.dart';
import 'package:kiln/features/portable/domain/use_cases/stop_portable_session_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';

class MockDetectPortableFinishUseCase extends Mock
    implements DetectPortableFinishUseCase {}

void main() {
  late MockPortableRepository repository;
  late MockDetectPortableFinishUseCase detectFinish;

  setUpAll(() => registerFallbackValue(DeviceModel.veazy));

  setUp(() {
    repository = MockPortableRepository();
    detectFinish = MockDetectPortableFinishUseCase();
    when(
      () => detectFinish(any(), any()),
    ).thenAnswer((_) async => right(some(DeviceFinish.blue)));
  });

  StartPortableSessionUseCase start() => StartPortableSessionUseCase(
    repository: repository,
    detectFinish: detectFinish,
  );

  group('StartPortableSessionUseCase', () {
    test('starts the session for the device', () async {
      when(
        () => repository.startSession('id', DeviceModel.veazy),
      ).thenAnswer((_) async => right(unit));

      final result = await start()('id', DeviceModel.veazy);

      expect(result.isRight(), isTrue);
      verify(() => repository.startSession('id', DeviceModel.veazy)).called(1);
      verify(() => detectFinish('id', DeviceModel.veazy)).called(1);
    });

    test('a failed finish detection does not fail the start', () async {
      when(
        () => repository.startSession('id', DeviceModel.veazy),
      ).thenAnswer((_) async => right(unit));
      when(
        () => detectFinish('id', DeviceModel.veazy),
      ).thenAnswer((_) async => left(const AppError.timeout()));

      final result = await start()('id', DeviceModel.veazy);

      expect(result.isRight(), isTrue);
    });

    test('passes errors through', () async {
      when(
        () => repository.startSession('id', DeviceModel.venty),
      ).thenAnswer((_) async => left(const AppError.protocol('bootloader')));

      final result = await start()('id', DeviceModel.venty);

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
      verifyNever(() => detectFinish(any(), any()));
    });
  });

  test('StopPortableSessionUseCase stops the session', () async {
    when(() => repository.stopSession()).thenAnswer((_) async {});

    await StopPortableSessionUseCase(repository: repository)();

    verify(() => repository.stopSession()).called(1);
  });
}
