// Runs the real data sources and repositories against the simulated devices,
// so demo mode exercises the same packets and write allow-lists as hardware.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/ble/ble_client.dart';
import 'package:kiln/core/ble/demo/ble_simulator.dart';
import 'package:kiln/core/ble/demo/demo_device_ids.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/data/data_sources/device_connection_data_source.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/portable/data/data_sources/portable_ble_data_source.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/repositories/portable_repository.dart';
import 'package:kiln/features/volcano/data/data_sources/volcano_ble_data_source.dart';
import 'package:kiln/features/volcano/domain/repositories/volcano_repository.dart';

T _settle<T>(FakeAsync async, Future<T> future) {
  late T value;
  future.then((v) => value = v);
  async.elapse(const Duration(seconds: 2));
  return value;
}

void main() {
  late BleClient ble;
  late ConnectionRepository connection;

  void connect(FakeAsync async, String deviceId) {
    ble = BleClient(BleSimulator());
    connection = ConnectionRepository(
      dataSource: DeviceConnectionDataSource(ble),
    );
    expect(_settle(async, connection.connect(deviceId)).isRight(), isTrue);
    expect(connection.status.value, ConnectionStatus.connected);
  }

  test('Veazy: session, boost, colour and the allow-list', () {
    fakeAsync((async) {
      connect(async, DemoDeviceIds.veazy);
      final portable = PortableRepository(
        dataSource: PortableBleDataSource(ble),
      );

      final started = _settle(
        async,
        portable.startSession(DemoDeviceIds.veazy, DeviceModel.veazy),
      );
      expect(started.isRight(), isTrue);
      expect(portable.status.value!.targetTemperature, 180);
      expect(portable.status.value!.batteryPercent, 76);
      expect(portable.status.value!.currentTemperature, isNull);

      expect(
        _settle(async, portable.readColorIndex()),
        const Right<AppError, Option<int>>(Some(2)),
      );

      expect(
        _settle(async, portable.setHeaterMode(HeaterMode.boost)).isRight(),
        isTrue,
      );
      async.elapse(const Duration(seconds: 30));
      final boosting = portable.status.value!;
      expect(boosting.heaterMode, HeaterMode.boost);
      expect(boosting.setpointReached, isTrue);
      // The packet holds 195 while boosting; the base stays 180.
      expect(boosting.targetTemperature, 180);

      expect(
        _settle(
          async,
          portable.setTargetTemperature(190),
        ).getLeft().toNullable(),
        isA<WriteNotVerifiedError>(),
      );

      portable.stopSession();
      connection.disconnect();
      async.flushTimers(flushPeriodicTimers: false);
    });
  });

  test('Venty: base temperature write round-trips', () {
    fakeAsync((async) {
      connect(async, DemoDeviceIds.venty);
      final portable = PortableRepository(
        dataSource: PortableBleDataSource(ble),
      );
      _settle(
        async,
        portable.startSession(DemoDeviceIds.venty, DeviceModel.venty),
      );
      expect(
        _settle(async, portable.setTargetTemperature(195)).isRight(),
        isTrue,
      );
      async.elapse(const Duration(seconds: 3));
      expect(portable.status.value!.targetTemperature, 195);

      portable.stopSession();
      connection.disconnect();
    });
  });

  test('Volcano: heats to the target, target and air follow', () {
    fakeAsync((async) {
      connect(async, DemoDeviceIds.volcano);
      final volcano = VolcanoRepository(dataSource: VolcanoBleDataSource(ble));

      expect(
        _settle(async, volcano.startSession(DemoDeviceIds.volcano)).isRight(),
        isTrue,
      );
      expect(volcano.status.value!.currentTemperature, 23);
      expect(volcano.status.value!.targetTemperature, 185);

      expect(_settle(async, volcano.setHeater(true)).isRight(), isTrue);
      async.elapse(const Duration(seconds: 40));
      expect(volcano.status.value!.heaterOn, isTrue);
      expect(volcano.status.value!.currentTemperature, 185);

      _settle(async, volcano.setTargetTemperature(200));
      _settle(async, volcano.setPump(true));
      expect(volcano.status.value!.targetTemperature, 200);
      expect(volcano.status.value!.pumpOn, isTrue);

      volcano.stopSession();
      connection.disconnect();
    });
  });

  // Real time: under fake_async the disconnect future of this stack never
  // completes, although it does at runtime.
  test('a demo device drops its session when it disconnects', () async {
    final ble = BleClient(BleSimulator(connectDelay: Duration.zero));
    final connection = ConnectionRepository(
      dataSource: DeviceConnectionDataSource(ble),
    );
    final portable = PortableRepository(dataSource: PortableBleDataSource(ble));
    expect((await connection.connect(DemoDeviceIds.veazy)).isRight(), isTrue);
    expect(
      (await portable.startSession(
        DemoDeviceIds.veazy,
        DeviceModel.veazy,
      )).isRight(),
      isTrue,
    );
    expect(portable.sessionActive.value, isTrue);

    expect((await connection.disconnect()).isRight(), isTrue);
    await pumpEventQueue();
    expect(portable.sessionActive.value, isFalse);
  });
}
