import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/use_cases/connect_device_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockConnectionRepository connection;
  late MockKnownDevicesRepository knownDevices;
  late MockScanRepository scan;
  late Signal<List<DiscoveredDevice>> results;
  late Signal<bool> scanning;
  late ConnectDeviceUseCase useCase;

  setUpAll(() => registerFallbackValue(veazy));

  setUp(() {
    connection = MockConnectionRepository();
    knownDevices = MockKnownDevicesRepository();
    scan = MockScanRepository();
    results = signal<List<DiscoveredDevice>>(const [discoveredVenty]);
    scanning = signal(false);
    when(() => scan.results).thenReturn(results);
    when(() => scan.scanning).thenReturn(scanning);
    when(() => scan.stop()).thenAnswer((_) async => right(unit));
    when(() => knownDevices.byId(any())).thenReturn(null);
    when(() => knownDevices.save(any())).thenAnswer((_) async => right(unit));
    when(
      () => knownDevices.setLastDeviceId(any()),
    ).thenAnswer((_) async => right(unit));
    when(() => connection.connect(any())).thenAnswer((_) async => right(unit));
    useCase = ConnectDeviceUseCase(
      connection: connection,
      knownDevices: knownDevices,
      scan: scan,
      clock: () => fixedNow,
    );
  });

  test('connects a discovered device and remembers it', () async {
    final result = await useCase(discoveredVenty.id);

    final expected = KnownDevice(
      id: discoveredVenty.id,
      name: discoveredVenty.name,
      model: discoveredVenty.model,
      lastConnectedAt: fixedNow,
    );
    expect(result.toNullable(), expected);
    verifyInOrder([
      () => connection.connect(discoveredVenty.id),
      () => knownDevices.save(expected),
      () => knownDevices.setLastDeviceId(discoveredVenty.id),
    ]);
  });

  test('keeps the settings of a known device', () async {
    final known = veazy.copyWith(detectedFinish: DeviceFinish.pink);
    when(() => knownDevices.byId(veazy.id)).thenReturn(known);

    final result = await useCase(veazy.id);

    expect(result.toNullable(), known.copyWith(lastConnectedAt: fixedNow));
  });

  test('stops a running scan before connecting', () async {
    scanning.value = true;

    await useCase(discoveredVenty.id);

    verifyInOrder([
      () => scan.stop(),
      () => connection.connect(discoveredVenty.id),
    ]);
  });

  test('unknown id', () async {
    final result = await useCase('nowhere');

    expect(result.getLeft().toNullable(), isA<DeviceNotFoundError>());
    verifyNever(() => connection.connect(any()));
  });

  test('a failed connect remembers nothing', () async {
    when(
      () => connection.connect(any()),
    ).thenAnswer((_) async => left(const AppError.timeout()));

    final result = await useCase(discoveredVenty.id);

    expect(result.getLeft().toNullable(), isA<TimeoutError>());
    verifyNever(() => knownDevices.save(any()));
    verifyNever(() => knownDevices.setLastDeviceId(any()));
  });

  test('passes a storage error on', () async {
    when(
      () => knownDevices.save(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase(discoveredVenty.id);

    expect(result.getLeft().toNullable(), isA<StorageError>());
    verifyNever(() => knownDevices.setLastDeviceId(any()));
  });

  test('passes a storage error from the last device id on', () async {
    when(
      () => knownDevices.setLastDeviceId(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));

    final result = await useCase(discoveredVenty.id);

    expect(result.getLeft().toNullable(), isA<StorageError>());
  });
}
