import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/background/domain/use_cases/device_session_target_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/start_device_session_use_case.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/devices/domain/repositories/known_devices_repository.dart';
import 'package:kiln/features/portable/domain/use_cases/start_portable_session_use_case.dart';
import 'package:kiln/features/volcano/domain/use_cases/start_volcano_session_use_case.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _MockConnection extends Mock implements ConnectionRepository {}

class _MockKnownDevices extends Mock implements KnownDevicesRepository {}

class _MockStartPortable extends Mock implements StartPortableSessionUseCase {}

class _MockStartVolcano extends Mock implements StartVolcanoSessionUseCase {}

void main() {
  setUpAll(() => registerFallbackValue(DeviceModel.veazy));

  test('target: the active device while connected', () {
    final connection = _MockConnection();
    final knownDevices = _MockKnownDevices();
    final status = signal(ConnectionStatus.connected);
    final device = signal<KnownDevice?>(
      const KnownDevice(id: 'vz', name: 'VZ', model: DeviceModel.veazy),
    );
    when(() => connection.status).thenReturn(status);
    when(() => knownDevices.activeDevice).thenReturn(device);
    final target = DeviceSessionTargetUseCase(
      connection: connection,
      knownDevices: knownDevices,
    );
    expect(target(), (id: 'vz', model: DeviceModel.veazy));
    status.value = ConnectionStatus.reconnecting;
    expect(target(), isNull);
    status.value = ConnectionStatus.connected;
    device.value = null;
    expect(target(), isNull);
  });

  test('start: the right session per model; nothing for Crafty+', () async {
    final portable = _MockStartPortable();
    final volcano = _MockStartVolcano();
    when(() => portable(any(), any())).thenAnswer((_) async => right(unit));
    when(() => volcano(any())).thenAnswer((_) async => right(unit));
    final start = StartDeviceSessionUseCase(
      startPortable: portable,
      startVolcano: volcano,
    );
    await start('vz', DeviceModel.veazy);
    await start('vh', DeviceModel.volcanoHybrid);
    await start('cp', DeviceModel.craftyPlus);
    verify(() => portable('vz', DeviceModel.veazy)).called(1);
    verify(() => volcano('vh')).called(1);
    verifyNoMoreInteractions(portable);
    verifyNoMoreInteractions(volcano);
  });
}
