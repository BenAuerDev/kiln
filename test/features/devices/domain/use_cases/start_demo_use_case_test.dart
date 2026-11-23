import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/use_cases/start_demo_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockConnectionRepository connection;
  late MockKnownDevicesRepository knownDevices;
  late MockScanRepository scan;
  late Signal<bool> scanning;
  late Signal<KnownDevice?> demoDevice;
  late StartDemoUseCase useCase;

  const demoVeazy = KnownDevice(
    id: 'demo:veazy',
    name: 'kiln demo',
    model: DeviceModel.veazy,
  );

  setUpAll(() => registerFallbackValue(demoVeazy));

  setUp(() {
    connection = MockConnectionRepository();
    knownDevices = MockKnownDevicesRepository();
    scan = MockScanRepository();
    scanning = signal(false);
    demoDevice = signal(null);
    when(() => scan.scanning).thenReturn(scanning);
    when(() => scan.stop()).thenAnswer((_) async => right(unit));
    when(() => knownDevices.demoDevice).thenReturn(demoDevice);
    when(() => knownDevices.byId(any())).thenReturn(null);
    when(() => knownDevices.save(any())).thenAnswer((_) async => right(unit));
    when(() => knownDevices.remove(any())).thenAnswer((_) async => right(unit));
    when(() => connection.connect(any())).thenAnswer((_) async => right(unit));
    useCase = StartDemoUseCase(
      connection: connection,
      knownDevices: knownDevices,
      scan: scan,
    );
  });

  test('saves the demo device in memory, then connects to it', () async {
    final result = await useCase(DeviceModel.veazy);

    expect(result, const Right<AppError, KnownDevice>(demoVeazy));
    verifyInOrder([
      () => knownDevices.save(demoVeazy),
      () => connection.connect('demo:veazy'),
    ]);
    verifyNever(() => knownDevices.setLastDeviceId(any()));
  });

  test('maps each supported model to its demo id', () async {
    for (final (model, id) in [
      (DeviceModel.volcanoHybrid, 'demo:volcano'),
      (DeviceModel.venty, 'demo:venty'),
    ]) {
      final result = await useCase(model);
      expect(result.getRight().toNullable()!.id, id);
    }
  });

  test('keeps the finish of a demo device that already exists', () async {
    const known = KnownDevice(
      id: 'demo:veazy',
      name: 'kiln demo',
      model: DeviceModel.veazy,
    );
    when(() => knownDevices.byId('demo:veazy')).thenReturn(known);
    final result = await useCase(DeviceModel.veazy);
    expect(result.getRight().toNullable(), same(known));
  });

  test('Crafty+ has no demo', () async {
    final result = await useCase(DeviceModel.craftyPlus);
    expect(result.getLeft().toNullable(), isA<DeviceNotFoundError>());
    verifyNever(() => connection.connect(any()));
  });

  test('stops a running scan first', () async {
    scanning.value = true;
    await useCase(DeviceModel.veazy);
    verifyInOrder([() => scan.stop(), () => connection.connect('demo:veazy')]);
  });

  test('forgets another demo device that was left behind', () async {
    demoDevice.value = const KnownDevice(
      id: 'demo:volcano',
      name: 'kiln demo',
      model: DeviceModel.volcanoHybrid,
    );
    await useCase(DeviceModel.veazy);
    verify(() => knownDevices.remove('demo:volcano')).called(1);
  });

  test('a failed connect forgets the demo device again', () async {
    when(
      () => connection.connect(any()),
    ).thenAnswer((_) async => left(const AppError.connectionFailed()));

    final result = await useCase(DeviceModel.veazy);

    expect(result.getLeft().toNullable(), isA<ConnectionFailedError>());
    verify(() => knownDevices.remove('demo:veazy')).called(1);
  });

  test('a failed save does not connect', () async {
    when(
      () => knownDevices.save(any()),
    ).thenAnswer((_) async => left(const AppError.storage()));
    final result = await useCase(DeviceModel.veazy);
    expect(result.isLeft(), isTrue);
    verifyNever(() => connection.connect(any()));
  });
}
