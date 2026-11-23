import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/ble/ble_exceptions.dart';
import 'package:kiln/features/volcano/data/data_sources/volcano_ble_data_source.dart';
import 'package:kiln/features/volcano/data/models/volcano_uuids.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  const id = 'AA:BB';
  late MockBleClient ble;
  late VolcanoBleDataSource dataSource;

  setUp(() {
    ble = MockBleClient();
    dataSource = VolcanoBleDataSource(ble);
    when(() => ble.write(any(), any(), any(), any())).thenAnswer((_) async {});
  });

  test('writes the target as 4 bytes to 10110003', () async {
    await dataSource.writeTargetTemperature(id, 185);
    verify(
      () => ble.write(
        id,
        VolcanoUuids.controlService,
        VolcanoUuids.targetTemperature,
        [0x3A, 0x07, 0x00, 0x00],
      ),
    ).called(1);
  });

  test('heater and pump write 0x00 to their on/off characteristics', () async {
    await dataSource.writeHeater(id, on: true);
    await dataSource.writeHeater(id, on: false);
    await dataSource.writePump(id, on: true);
    await dataSource.writePump(id, on: false);
    for (final uuid in [
      VolcanoUuids.heaterOn,
      VolcanoUuids.heaterOff,
      VolcanoUuids.pumpOn,
      VolcanoUuids.pumpOff,
    ]) {
      verify(
        () => ble.write(id, VolcanoUuids.controlService, uuid, [0x00]),
      ).called(1);
    }
  });

  test('reads registers from the state service', () async {
    when(
      () => ble.read(id, VolcanoUuids.stateService, VolcanoUuids.register1),
    ).thenAnswer((_) async => [0x20, 0x20]);
    final register = await dataSource.readRegister1(id);
    expect(register.heaterOn, isTrue);
    expect(register.pumpOn, isTrue);
  });

  test('decodes temperature notifications', () async {
    when(
      () => ble.subscribe(
        id,
        VolcanoUuids.controlService,
        VolcanoUuids.currentTemperature,
      ),
    ).thenAnswer(
      (_) => Stream.fromIterable([
        [0xC5, 0x03],
        [0xFF, 0xFF],
      ]),
    );
    expect(await dataSource.watchCurrentTemperature(id).toList(), [96.5, null]);
  });

  test('passes BLE exceptions through', () {
    when(
      () => ble.read(any(), any(), any()),
    ).thenThrow(const BleTimeoutException('read'));
    expect(
      () => dataSource.readTargetTemperature(id),
      throwsA(isA<BleTimeoutException>()),
    );
  });
}
