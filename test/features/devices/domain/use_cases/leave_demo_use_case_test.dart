import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/use_cases/leave_demo_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockConnectionRepository connection;
  late MockKnownDevicesRepository knownDevices;
  late Signal<KnownDevice?> demoDevice;
  late Signal<String?> activeId;
  late LeaveDemoUseCase useCase;

  const demo = KnownDevice(
    id: 'demo:volcano',
    name: 'kiln demo',
    model: DeviceModel.volcanoHybrid,
  );

  setUp(() {
    connection = MockConnectionRepository();
    knownDevices = MockKnownDevicesRepository();
    demoDevice = signal(demo);
    activeId = signal('demo:volcano');
    when(() => knownDevices.demoDevice).thenReturn(demoDevice);
    when(() => connection.activeDeviceId).thenReturn(activeId);
    when(
      () => connection.disconnect(byUser: false),
    ).thenAnswer((_) async => right(unit));
    when(() => knownDevices.remove(any())).thenAnswer((_) async => right(unit));
    useCase = LeaveDemoUseCase(
      connection: connection,
      knownDevices: knownDevices,
    );
  });

  test('disconnects the active demo device and forgets it', () async {
    final result = await useCase();
    expect(result, const Right<AppError, Option<Unit>>(Some(unit)));
    verifyInOrder([
      () => connection.disconnect(byUser: false),
      () => knownDevices.remove('demo:volcano'),
    ]);
  });

  test('leaves a real active device connected', () async {
    activeId.value = 'real-id';
    await useCase();
    verifyNever(() => connection.disconnect(byUser: any(named: 'byUser')));
    verify(() => knownDevices.remove('demo:volcano')).called(1);
  });

  test('does nothing without a demo', () async {
    demoDevice.value = null;
    final result = await useCase();
    expect(result, const Right<AppError, Option<Unit>>(None()));
    verifyNever(() => connection.disconnect(byUser: any(named: 'byUser')));
    verifyNever(() => knownDevices.remove(any()));
  });

  test('passes on a failed disconnect and keeps the demo', () async {
    when(
      () => connection.disconnect(byUser: false),
    ).thenAnswer((_) async => left(const AppError.connectionFailed()));
    final result = await useCase();
    expect(result.isLeft(), isTrue);
    verifyNever(() => knownDevices.remove(any()));
  });
}
