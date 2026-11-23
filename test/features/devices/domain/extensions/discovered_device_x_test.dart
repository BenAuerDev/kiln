import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/extensions/discovered_device_x.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/domain/models/signal_strength.dart';

void main() {
  DiscoveredDevice at(int rssi) => DiscoveredDevice(
    id: 'id',
    name: 'S&B VZ1',
    model: DeviceModel.veazy,
    rssi: rssi,
  );

  test('signal strength buckets', () {
    expect(at(-40).signalStrength, SignalStrength.strong);
    expect(at(-65).signalStrength, SignalStrength.strong);
    expect(at(-66).signalStrength, SignalStrength.fair);
    expect(at(-80).signalStrength, SignalStrength.fair);
    expect(at(-81).signalStrength, SignalStrength.weak);
  });
}
