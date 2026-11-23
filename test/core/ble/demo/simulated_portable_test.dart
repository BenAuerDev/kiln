import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/ble/demo/simulated_portable.dart';

List<int> _packet(int command, [Map<int, int> bytes = const {}]) {
  final packet = List<int>.filled(20, 0)..[0] = command;
  bytes.forEach((index, value) => packet[index] = value);
  return packet;
}

int _target(List<int> status) => status[4] | (status[5] << 8);

void main() {
  late SimulatedPortable device;
  late List<List<int>> received;
  late StreamSubscription<List<int>> subscription;

  void setUpDevice(FakeAsync async, {bool isVeazy = true}) {
    device = SimulatedPortable(isVeazy: isVeazy);
    received = [];
    subscription = device.notifications.listen(received.add);
    device.start();
  }

  List<int> status(FakeAsync async) {
    device.write(_packet(0x01));
    async.elapse(const Duration(milliseconds: 50));
    return received.lastWhere((p) => p[0] == 0x01);
  }

  tearDown(() => subscription.cancel());

  test('reports no current temperature and the base target', () {
    fakeAsync((async) {
      setUpDevice(async);
      final packet = status(async);
      expect(packet.length, 20);
      expect([packet[2], packet[3]], [0x00, 0x80]);
      expect(_target(packet), 1800);
      expect(packet[6], 15);
      expect(packet[7], 15);
      expect(packet[8], 76);
      expect(packet[11], 0);
      device.stop();
    });
  });

  test('firmware info says the application runs', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write(_packet(0x02));
      async.elapse(const Duration(milliseconds: 50));
      expect(received.single.sublist(0, 2), [0x02, 0x01]);
      device.stop();
    });
  });

  test('identity carries the colour on a Veazy only', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write(_packet(0x05));
      async.elapse(const Duration(milliseconds: 50));
      expect(received.single[18], 2);
      device.stop();
    });
    fakeAsync((async) {
      setUpDevice(async, isVeazy: false);
      device.write(_packet(0x05));
      async.elapse(const Duration(milliseconds: 50));
      expect(received.single[18], 0);
      device.stop();
    });
  });

  test('applies only the fields of the write mask', () {
    fakeAsync((async) {
      setUpDevice(async);
      // Mask 0x02 (target) with a non-zero boost byte: boost must stay.
      device.write(_packet(0x01, {1: 0x02, 4: 0x3A, 5: 0x07, 6: 99}));
      final packet = status(async);
      expect(_target(packet), 1850);
      expect(packet[6], 15);
      device.stop();
    });
  });

  test('heats to the setpoint and sets the reached bit', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write(_packet(0x01, {1: 0x20, 11: 1}));
      async.elapse(const Duration(seconds: 1));
      expect(status(async)[14] & 0x02, 0);
      async.elapse(const Duration(seconds: 30));
      final packet = status(async);
      expect(packet[11], 1);
      expect(packet[14] & 0x02, 0x02);
      expect(packet[9], greaterThan(0));
      device.stop();
    });
  });

  test('boost reports the boosted setpoint; mode 1 does not end it', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write(_packet(0x01, {1: 0x20, 11: 2}));
      expect(_target(status(async)), 1950);
      device.write(_packet(0x01, {1: 0x20, 11: 1}));
      expect(status(async)[11], 2);
      device.write(_packet(0x01, {1: 0x20, 11: 0}));
      device.write(_packet(0x01, {1: 0x20, 11: 1}));
      final packet = status(async);
      expect(packet[11], 1);
      expect(_target(packet), 1800);
      device.stop();
    });
  });

  test('superboost stacks both offsets, capped at 210 °C', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write(_packet(0x01, {1: 0x20, 11: 3}));
      expect(_target(status(async)), 2100);
      device.stop();
    });
  });

  test('settings writes change only writable bits, never 0x04', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write(_packet(0x01, {1: 0x80, 14: 0x0D, 15: 0x0D}));
      expect(status(async)[14], 0x09);
      device.stop();
    });
  });

  test('vibration write is answered with the new value', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write([0x06, 0x08, 0, 0, 0, 0, 0]);
      async.elapse(const Duration(milliseconds: 50));
      expect(received.single, [0x06, 0x00, 5, 0, 0, 0, 0]);
      device.stop();
    });
  });

  test('switches itself off after the auto-off time', () {
    fakeAsync((async) {
      setUpDevice(async);
      device.write(_packet(0x01, {1: 0x20, 11: 1}));
      async.elapse(const Duration(minutes: 4, seconds: 1));
      expect(status(async)[11], 0);
      device.stop();
    });
  });

  test('stays silent after stop', () {
    fakeAsync((async) {
      setUpDevice(async);
      device
        ..write(_packet(0x01))
        ..stop();
      async.elapse(const Duration(milliseconds: 50));
      expect(received, isEmpty);
    });
  });
}
