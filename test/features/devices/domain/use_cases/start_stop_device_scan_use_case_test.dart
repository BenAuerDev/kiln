import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/use_cases/start_device_scan_use_case.dart';
import 'package:kiln/features/devices/domain/use_cases/stop_device_scan_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockScanRepository scan;

  setUp(() => scan = MockScanRepository());

  group('StartDeviceScanUseCase', () {
    test('starts a scan', () async {
      when(() => scan.start()).thenAnswer((_) async => right(unit));

      final result = await StartDeviceScanUseCase(scan: scan)();

      expect(result, right<AppError, Unit>(unit));
      verify(() => scan.start()).called(1);
    });

    test('passes errors on', () async {
      when(
        () => scan.start(),
      ).thenAnswer((_) async => left(const AppError.bluetoothUnavailable()));

      final result = await StartDeviceScanUseCase(scan: scan)();

      expect(result.getLeft().toNullable(), isA<BluetoothUnavailableError>());
    });
  });

  group('StopDeviceScanUseCase', () {
    test('stops the scan', () async {
      when(() => scan.stop()).thenAnswer((_) async => right(unit));

      final result = await StopDeviceScanUseCase(scan: scan)();

      expect(result.isRight(), isTrue);
      verify(() => scan.stop()).called(1);
    });

    test('passes errors on', () async {
      when(
        () => scan.stop(),
      ).thenAnswer((_) async => left(const AppError.protocol('x')));

      final result = await StopDeviceScanUseCase(scan: scan)();

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
    });
  });
}
