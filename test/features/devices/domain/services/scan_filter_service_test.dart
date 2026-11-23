import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/services/scan_filter_service.dart';

import '../../helpers/fixtures.dart';

void main() {
  const service = ScanFilterService();

  group('modelFor by advertised name', () {
    final cases = {
      'S&B VOLCANO H': DeviceModel.volcanoHybrid,
      'Storz&Bickel Volcano': DeviceModel.volcanoHybrid,
      'S&B VY123456': DeviceModel.venty,
      'S&B VY___JP4': DeviceModel.venty,
      'S&B VZ123456': DeviceModel.veazy,
      's&b vz123456': DeviceModel.veazy,
      'STORZ&BICKEL': DeviceModel.craftyPlus,
      'Storz&Bickel': DeviceModel.craftyPlus,
      'S&B CRAFTY': DeviceModel.craftyPlus,
    };
    for (final MapEntry(key: name, value: model) in cases.entries) {
      test('$name -> ${model.name}', () {
        expect(service.modelFor(name: name), model);
      });
    }

    test('ignores names that are not S&B', () {
      expect(service.modelFor(name: 'JBL Flip'), isNull);
      expect(service.modelFor(name: 'My Volcano speaker'), isNull);
      expect(service.modelFor(name: ''), isNull);
    });
  });

  group('modelFor by service UUID when the name does not tell', () {
    test('volcano services', () {
      expect(
        service.modelFor(
          name: '',
          serviceUuids: const ['10110000-5354-4F52-5A26-4249434B454C'],
        ),
        DeviceModel.volcanoHybrid,
      );
    });

    test('crafty services', () {
      expect(
        service.modelFor(
          name: '',
          serviceUuids: const ['00000002-4c45-4b43-4942-265a524f5453'],
        ),
        DeviceModel.craftyPlus,
      );
    });

    test('the shared Venty/Veazy service alone is ambiguous', () {
      expect(
        service.modelFor(
          name: '',
          serviceUuids: const [ScanFilterService.portableServiceUuid],
        ),
        isNull,
      );
    });

    test('the name wins over services', () {
      expect(
        service.modelFor(
          name: 'S&B VZ1',
          serviceUuids: const ['10110000-5354-4f52-5a26-4249434b454c'],
        ),
        DeviceModel.veazy,
      );
    });
  });

  test('discoveredFrom keeps S&B devices, strongest first', () {
    final result = service.discoveredFrom([
      hit('S&B VY1', id: 'a', rssi: -80),
      hit('Headphones', id: 'b', rssi: -30),
      hit('S&B VOLCANO H', id: 'c', rssi: -50),
    ]);

    expect(result.map((d) => d.id), ['c', 'a']);
    expect(result.first.model, DeviceModel.volcanoHybrid);
    expect(result.first.name, 'S&B VOLCANO H');
    expect(result.first.rssi, -50);
  });

  test('discoveredFrom with no hits is empty', () {
    expect(service.discoveredFrom(const []), isEmpty);
  });
}
