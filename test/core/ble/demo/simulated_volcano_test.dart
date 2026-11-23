import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/ble/ble_exceptions.dart';
import 'package:kiln/core/ble/demo/simulated_volcano.dart';

double _celsius(List<int> bytes) => (bytes[0] | (bytes[1] << 8)) / 10;

void main() {
  const control = SimulatedVolcano.controlService;
  const state = SimulatedVolcano.stateService;

  test('reads room temperature, 185 °C target and heater off', () {
    final volcano = SimulatedVolcano();
    expect(
      _celsius(volcano.read(control, SimulatedVolcano.currentTemperature)),
      23,
    );
    expect(
      _celsius(volcano.read(control, SimulatedVolcano.targetTemperature)),
      185,
    );
    final register = volcano.read(state, SimulatedVolcano.register1);
    expect(register[0] & 0x20, 0);
  });

  test('target writes need 4 bytes and are notified', () {
    fakeAsync((async) {
      final volcano = SimulatedVolcano();
      final notified = <List<int>>[];
      volcano
          .notifications(SimulatedVolcano.targetTemperature)
          .listen(notified.add);
      volcano.write(control, SimulatedVolcano.targetTemperature, [
        0x6C,
        0x07,
        0,
        0,
      ]);
      async.flushMicrotasks();
      expect(_celsius(notified.single), 190);
      expect(
        () => volcano.write(control, SimulatedVolcano.targetTemperature, [
          0x6C,
          0x07,
        ]),
        throwsA(isA<BleOperationException>()),
      );
    });
  });

  test('heater on heats in about 4 °C steps up to the target', () {
    fakeAsync((async) {
      final volcano = SimulatedVolcano()..start();
      final temperatures = <double>[];
      final registers = <List<int>>[];
      volcano
          .notifications(SimulatedVolcano.currentTemperature)
          .listen((bytes) => temperatures.add(_celsius(bytes)));
      volcano.notifications(SimulatedVolcano.register1).listen(registers.add);
      volcano.write(control, SimulatedVolcano.heaterOn, [0]);
      async.elapse(const Duration(seconds: 40));
      volcano.stop();

      expect(registers.single[0] & 0x20, 0x20);
      expect(temperatures.last, 185);
      for (var i = 1; i < temperatures.length - 1; i++) {
        expect(temperatures[i] - temperatures[i - 1], closeTo(4, 0.6));
      }
    });
  });

  test('pump on and off update register 1', () {
    fakeAsync((async) {
      final volcano = SimulatedVolcano();
      final registers = <List<int>>[];
      volcano.notifications(SimulatedVolcano.register1).listen(registers.add);
      volcano
        ..write(control, SimulatedVolcano.pumpOn, [0])
        ..write(control, SimulatedVolcano.pumpOff, [0]);
      async.flushMicrotasks();
      expect(registers.map((r) => r[1] & 0x20), [0x20, 0]);
    });
  });

  test('anything else does not exist', () {
    final volcano = SimulatedVolcano();
    expect(
      () => volcano.write(control, SimulatedVolcano.register1, [0]),
      throwsA(isA<BleCharacteristicNotFoundException>()),
    );
    expect(
      () => volcano.read(control, '10110015-5354-4f52-5a26-4249434b454c'),
      throwsA(isA<BleCharacteristicNotFoundException>()),
    );
  });
}
