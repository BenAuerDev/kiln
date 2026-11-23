import '../../../../core/ble/ble_client.dart';
import '../../../../core/ble/ble_connection_state.dart';
import '../models/volcano_codec.dart';
import '../models/volcano_registers_dto.dart';
import '../models/volcano_uuids.dart';
import '../models/volcano_write_safety.dart';

/// BLE I/O for the Volcano Hybrid. The official app sends no init sequence:
/// it only reads and subscribes.
class VolcanoBleDataSource {
  VolcanoBleDataSource(this._ble);

  final BleClient _ble;

  /// `null` when the device reports no valid reading.
  Future<double?> readCurrentTemperature(String deviceId) async =>
      VolcanoCodec.decodeTemperature(
        await _readControl(deviceId, VolcanoUuids.currentTemperature),
      );

  Future<double?> readTargetTemperature(String deviceId) async =>
      VolcanoCodec.decodeTemperature(
        await _readControl(deviceId, VolcanoUuids.targetTemperature),
      );

  Future<VolcanoRegister1Dto> readRegister1(String deviceId) async =>
      VolcanoRegister1Dto.decode(
        await _readState(deviceId, VolcanoUuids.register1),
      );

  Future<VolcanoRegister2Dto> readRegister2(String deviceId) async =>
      VolcanoRegister2Dto.decode(
        await _readState(deviceId, VolcanoUuids.register2),
      );

  Future<VolcanoRegister3Dto> readRegister3(String deviceId) async =>
      VolcanoRegister3Dto.decode(
        await _readState(deviceId, VolcanoUuids.register3),
      );

  Stream<double?> watchCurrentTemperature(String deviceId) => _ble
      .subscribe(
        deviceId,
        VolcanoUuids.controlService,
        VolcanoUuids.currentTemperature,
      )
      .map(VolcanoCodec.decodeTemperature);

  Stream<double?> watchTargetTemperature(String deviceId) => _ble
      .subscribe(
        deviceId,
        VolcanoUuids.controlService,
        VolcanoUuids.targetTemperature,
      )
      .map(VolcanoCodec.decodeTemperature);

  Stream<VolcanoRegister1Dto> watchRegister1(String deviceId) => _ble
      .subscribe(deviceId, VolcanoUuids.stateService, VolcanoUuids.register1)
      .map(VolcanoRegister1Dto.decode);

  Stream<VolcanoRegister2Dto> watchRegister2(String deviceId) => _ble
      .subscribe(deviceId, VolcanoUuids.stateService, VolcanoUuids.register2)
      .map(VolcanoRegister2Dto.decode);

  Stream<BleConnectionState> connectionState(String deviceId) =>
      _ble.connectionState(deviceId);

  Future<void> writeTargetTemperature(String deviceId, int celsius) =>
      _writeControl(
        deviceId,
        VolcanoUuids.targetTemperature,
        VolcanoCodec.encodeTargetTemperature(celsius),
      );

  Future<void> writeHeater(String deviceId, {required bool on}) =>
      _writeControl(
        deviceId,
        on ? VolcanoUuids.heaterOn : VolcanoUuids.heaterOff,
        VolcanoCodec.command,
      );

  Future<void> writePump(String deviceId, {required bool on}) => _writeControl(
    deviceId,
    on ? VolcanoUuids.pumpOn : VolcanoUuids.pumpOff,
    VolcanoCodec.command,
  );

  Future<List<int>> _readControl(String deviceId, String characteristic) =>
      _ble.read(deviceId, VolcanoUuids.controlService, characteristic);

  Future<List<int>> _readState(String deviceId, String characteristic) =>
      _ble.read(deviceId, VolcanoUuids.stateService, characteristic);

  Future<void> _writeControl(
    String deviceId,
    String characteristic,
    List<int> value,
  ) async {
    VolcanoWriteSafety.check(characteristic);
    await _ble.write(
      deviceId,
      VolcanoUuids.controlService,
      characteristic,
      value,
    );
  }
}
