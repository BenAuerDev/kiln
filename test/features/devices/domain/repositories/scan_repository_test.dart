import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/ble/ble_exceptions.dart';
import 'package:kiln/core/ble/ble_scan_hit.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/repositories/scan_repository.dart';
import 'package:kiln/features/devices/domain/services/scan_filter_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockDeviceScanDataSource dataSource;
  late StreamController<List<BleScanHit>> hits;
  late ScanRepository repository;

  const duration = Duration(seconds: 10);

  setUpAll(() => registerFallbackValue(Duration.zero));

  setUp(() {
    dataSource = MockDeviceScanDataSource();
    hits = StreamController<List<BleScanHit>>();
    when(() => dataSource.scan(any())).thenAnswer((_) => hits.stream);
    when(() => dataSource.stop()).thenAnswer((_) async {});
    repository = ScanRepository(
      dataSource: dataSource,
      filter: const ScanFilterService(),
      scanDuration: duration,
    );
  });

  test('start filters hits into S&B devices', () async {
    final started = repository.start();
    expect(repository.scanning.value, isTrue);
    hits.add([
      hit('S&B VZ1', id: 'a', rssi: -70),
      hit('Speaker', id: 'b'),
      hit('S&B VOLCANO H', id: 'c', rssi: -40),
    ]);

    final result = await started;

    expect(result.isRight(), isTrue);
    expect(repository.results.value.map((d) => d.id), ['c', 'a']);
    expect(repository.results.value.last.model, DeviceModel.veazy);
    verify(() => dataSource.scan(duration)).called(1);
  });

  test('start reports a BLE error and stops scanning', () async {
    final started = repository.start();
    hits.addError(const BlePermissionException('denied'));

    final result = await started;

    expect(result.getLeft().toNullable(), isA<PermissionDeniedError>());
    expect(repository.scanning.value, isFalse);
  });

  test('a new scan clears old results', () async {
    final first = repository.start();
    hits.add([hit('S&B VZ1')]);
    await first;
    hits = StreamController<List<BleScanHit>>();

    unawaited(repository.start());

    expect(repository.results.value, isEmpty);
  });

  test('the scan ends by itself after the duration', () {
    fakeAsync((async) {
      unawaited(repository.start());
      hits.add([hit('S&B VZ1')]);
      async.elapse(duration - const Duration(milliseconds: 1));
      expect(repository.scanning.value, isTrue);

      async.elapse(const Duration(milliseconds: 1));
      expect(repository.scanning.value, isFalse);
      expect(repository.results.value, hasLength(1));
    });
  });

  test('the scan ends when the stream closes', () async {
    final started = repository.start();
    await hits.close();

    expect((await started).isRight(), isTrue);
    expect(repository.scanning.value, isFalse);
  });

  group('stop', () {
    test('stops a running scan and keeps results', () async {
      final started = repository.start();
      hits.add([hit('S&B VZ1')]);
      await started;

      final result = await repository.stop();

      expect(result.isRight(), isTrue);
      expect(repository.scanning.value, isFalse);
      expect(repository.results.value, hasLength(1));
      verify(() => dataSource.stop()).called(1);
    });

    test('does not touch BLE when idle', () async {
      final result = await repository.stop();

      expect(result.isRight(), isTrue);
      verifyNever(() => dataSource.stop());
    });

    test('maps a BLE error', () async {
      unawaited(repository.start());
      when(() => dataSource.stop()).thenThrow(const BleOperationException('x'));

      final result = await repository.stop();

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
      expect(repository.scanning.value, isFalse);
    });
  });
}
