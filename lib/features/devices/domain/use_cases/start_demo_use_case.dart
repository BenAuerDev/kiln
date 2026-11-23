import 'package:fpdart/fpdart.dart';

import '../../../../core/ble/demo/demo_device_ids.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/device_model.dart';
import '../models/known_device.dart';
import '../repositories/connection_repository.dart';
import '../repositories/known_devices_repository.dart';
import '../repositories/scan_repository.dart';

/// Connects to the simulated [DeviceModel]. The demo device is kept in
/// memory only and never becomes the device kiln reconnects to.
class StartDemoUseCase {
  StartDemoUseCase({
    ConnectionRepository? connection,
    KnownDevicesRepository? knownDevices,
    ScanRepository? scan,
  }) : _connection = connection ?? sl<ConnectionRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _scan = scan ?? sl<ScanRepository>();

  final ConnectionRepository _connection;
  final KnownDevicesRepository _knownDevices;
  final ScanRepository _scan;

  static const models = [
    DeviceModel.volcanoHybrid,
    DeviceModel.venty,
    DeviceModel.veazy,
  ];

  Future<Either<AppError, KnownDevice>> call(DeviceModel model) async {
    final id = switch (model) {
      DeviceModel.volcanoHybrid => DemoDeviceIds.volcano,
      DeviceModel.venty => DemoDeviceIds.venty,
      DeviceModel.veazy => DemoDeviceIds.veazy,
      DeviceModel.craftyPlus => null,
    };
    if (id == null) return left(const AppError.deviceNotFound());

    if (_scan.scanning.value) await _scan.stop();

    // Another demo device is left behind, a real one stays saved.
    final previous = _knownDevices.demoDevice.value;
    if (previous != null && previous.id != id) {
      await _knownDevices.remove(previous.id);
    }
    final device =
        _knownDevices.byId(id) ??
        KnownDevice(id: id, name: 'kiln demo', model: model);
    final saved = await _knownDevices.save(device);
    if (saved case Left(value: final error)) return left(error);

    final connected = await _connection.connect(id);
    if (connected case Left(value: final error)) {
      await _knownDevices.remove(id);
      return left(error);
    }
    return right(device);
  }
}
