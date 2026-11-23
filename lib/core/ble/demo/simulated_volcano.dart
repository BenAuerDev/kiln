import 'dart:async';
import 'dart:math' as math;

import '../ble_exceptions.dart';

/// A Volcano Hybrid for demo mode, written from docs/protocol.md. It heats
/// faster than the real one (about 30 s from room temperature to 185 °C) and,
/// like the real one, reports the current temperature in steps of about 4 °C.
///
/// Only the characteristics kiln uses exist; anything else fails the way a
/// missing characteristic does on a real device.
class SimulatedVolcano {
  static const _suffix = '-5354-4f52-5a26-4249434b454c';
  static const stateService = '10100000$_suffix';
  static const controlService = '10110000$_suffix';
  static const register1 = '1010000c$_suffix';
  static const register2 = '1010000d$_suffix';
  static const register3 = '1010000e$_suffix';
  static const currentTemperature = '10110001$_suffix';
  static const targetTemperature = '10110003$_suffix';
  static const heaterOn = '1011000f$_suffix';
  static const heaterOff = '10110010$_suffix';
  static const pumpOn = '10110013$_suffix';
  static const pumpOff = '10110014$_suffix';

  static const _readable = {
    stateService: {register1, register2, register3},
    controlService: {currentTemperature, targetTemperature},
  };
  static const _writable = {
    controlService: {targetTemperature, heaterOn, heaterOff, pumpOn, pumpOff},
  };

  static const tick = Duration(milliseconds: 250);
  static const _ambient = 23.0;
  static const _heatPerSecond = 5.5;
  static const _coolPerSecond = 1.5;
  static const _reportStep = 4.0;
  static const _heaterBit = 0x0020;
  static const _autoShutdownBit = 0x0200;
  static const _pumpBit = 0x2000;

  final _notifications = StreamController<(String, List<int>)>.broadcast();
  Timer? _ticker;

  double _celsius = _ambient;
  double _reported = _ambient;
  int _targetTenths = 1850;
  bool _heater = false;
  bool _pump = false;

  /// Notifications of [characteristicUuid].
  Stream<List<int>> notifications(String characteristicUuid) => _notifications
      .stream
      .where((n) => n.$1 == characteristicUuid)
      .map((n) => n.$2);

  void start() => _ticker ??= Timer.periodic(tick, (_) => _advance(tick));

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Throws [BleCharacteristicNotFoundException] for anything but the
  /// characteristics kiln reads.
  void checkReadable(String serviceUuid, String characteristicUuid) =>
      _check(_readable, serviceUuid, characteristicUuid);

  List<int> read(String serviceUuid, String characteristicUuid) {
    checkReadable(serviceUuid, characteristicUuid);
    return switch (characteristicUuid) {
      currentTemperature => _uint16((_reported * 10).round()),
      targetTemperature => _uint16(_targetTenths),
      register1 => _uint16(_register1),
      _ => _uint16(0),
    };
  }

  void write(String serviceUuid, String characteristicUuid, List<int> value) {
    _check(_writable, serviceUuid, characteristicUuid);
    switch (characteristicUuid) {
      case targetTemperature:
        if (value.length != 4) {
          throw const BleOperationException('target: expected 4 bytes');
        }
        final tenths = value[0] | (value[1] << 8);
        _targetTenths = tenths.clamp(400, 2300);
        _notify(targetTemperature, _uint16(_targetTenths));
      case heaterOn || heaterOff:
        _heater = characteristicUuid == heaterOn;
        _notify(register1, _uint16(_register1));
      case pumpOn || pumpOff:
        _pump = characteristicUuid == pumpOn;
        _notify(register1, _uint16(_register1));
    }
  }

  int get _register1 =>
      _autoShutdownBit | (_heater ? _heaterBit : 0) | (_pump ? _pumpBit : 0);

  void _advance(Duration elapsed) {
    final seconds = elapsed.inMilliseconds / 1000;
    final goal = _heater ? _targetTenths / 10 : _ambient;
    if (_celsius < goal) {
      _celsius = math.min(goal, _celsius + _heatPerSecond * seconds);
    } else {
      _celsius = math.max(goal, _celsius - _coolPerSecond * seconds);
    }
    final settled = _celsius == goal && _reported != goal;
    if ((_celsius - _reported).abs() >= _reportStep || settled) {
      _reported = _celsius;
      _notify(currentTemperature, _uint16((_reported * 10).round()));
    }
  }

  void _notify(String characteristicUuid, List<int> value) =>
      _notifications.add((characteristicUuid, value));

  void _check(
    Map<String, Set<String>> table,
    String serviceUuid,
    String characteristicUuid,
  ) {
    if (!(table[serviceUuid]?.contains(characteristicUuid) ?? false)) {
      throw BleCharacteristicNotFoundException(
        'demo volcano: $characteristicUuid',
      );
    }
  }

  static List<int> _uint16(int value) => [value & 0xFF, (value >> 8) & 0xFF];
}
