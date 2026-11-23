import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/extensions/device_model_x.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';

void main() {
  test('isPortable means the shared Venty/Veazy protocol', () {
    expect(DeviceModel.venty.isPortable, isTrue);
    expect(DeviceModel.veazy.isPortable, isTrue);
    expect(DeviceModel.volcanoHybrid.isPortable, isFalse);
    expect(DeviceModel.craftyPlus.isPortable, isFalse);
  });

  test('only Crafty+ is unsupported', () {
    expect(DeviceModel.values.where((m) => !m.isSupported), [
      DeviceModel.craftyPlus,
    ]);
  });

  test('displayName is plain text', () {
    expect(DeviceModel.volcanoHybrid.displayName, 'Volcano Hybrid');
    expect(DeviceModel.venty.displayName, 'Venty');
    expect(DeviceModel.veazy.displayName, 'Veazy');
    expect(DeviceModel.craftyPlus.displayName, 'Crafty+');
  });
}
