import 'dart:async';
import 'dart:math' as math;

/// A Venty or Veazy for demo mode. It answers bytes as described in
/// docs/protocol.md and is written from that document, not from kiln's own
/// encoders, so a wrong packet from kiln shows up instead of being mirrored.
///
/// Like the real devices it never reports a current temperature (`0x8000`),
/// replies only to requests, keeps boosting when sent heater mode 1 and only
/// accepts the settings bits kiln may write.
class SimulatedPortable {
  SimulatedPortable({required this.isVeazy});

  final bool isVeazy;

  static const serviceUuid = '00000000-5354-4f52-5a26-4249434b454c';
  static const characteristicUuid = '00000001-5354-4f52-5a26-4249434b454c';

  static const tick = Duration(milliseconds: 250);
  static const _replyDelay = Duration(milliseconds: 20);
  static const _ambient = 25.0;
  static const _heatPerSecond = 9.0;
  static const _coolPerSecond = 3.0;
  static const _autoOff = Duration(minutes: 4);
  static const _batteryDrainEvery = Duration(seconds: 20);
  static const _maxCelsius = 210;

  /// Settings bits a `01 80` write may change: °F, eco charge, eco voltage,
  /// boost visualisation. Never `0x04`.
  static const _writableSettings = 0x01 | 0x08 | 0x20 | 0x40;
  static const _reachedBit = 0x02;

  final _notifications = StreamController<List<int>>.broadcast();
  Timer? _ticker;
  bool _running = false;

  int _baseTenths = 1800;
  int _boost = 15;
  int _superBoost = 15;
  int _battery = 76;
  int _heaterMode = 0;
  late int _settings = isVeazy ? 0 : 0x40;
  bool _vibration = true;
  double _celsius = _ambient;
  Duration _autoOffLeft = Duration.zero;
  Duration _sinceDrain = Duration.zero;

  Stream<List<int>> get notifications => _notifications.stream;

  void start() {
    _running = true;
    _ticker ??= Timer.periodic(tick, (_) => _advance(tick));
  }

  void stop() {
    _running = false;
    _ticker?.cancel();
    _ticker = null;
  }

  void write(List<int> bytes) {
    if (bytes.isEmpty) return;
    switch (bytes[0]) {
      case 0x01:
        _applyStatusWrite(bytes);
        _reply(_statusPacket);
      case 0x02:
        _reply(() => _packet(0x02)..[1] = 0x01);
      case 0x05:
        // Byte 18: colour on a Veazy (2 = blue). Not asked of a Venty.
        _reply(() => _packet(0x05)..[18] = isVeazy ? 2 : 0);
      case 0x06:
        if (bytes.length >= 6 && bytes[1] & 0x08 != 0) {
          _vibration = bytes[5] != 0;
        }
        _reply(() => [0x06, 0x00, 5, 0x00, 0x00, if (_vibration) 1 else 0, 0]);
      case 0x0D:
        // Find my device: the real one vibrates and blinks, nothing to send.
        break;
    }
  }

  void _applyStatusWrite(List<int> bytes) {
    if (bytes.length < 16) return;
    final mask = bytes[1];
    if (mask & 0x02 != 0) _baseTenths = bytes[4] | (bytes[5] << 8);
    if (mask & 0x04 != 0) _boost = bytes[6];
    if (mask & 0x08 != 0) _superBoost = bytes[7];
    if (mask & 0x20 != 0) _setHeaterMode(bytes[11]);
    if (mask & 0x80 != 0) {
      final change = bytes[15] & _writableSettings;
      _settings = (_settings & ~change) | (bytes[14] & change);
    }
  }

  void _setHeaterMode(int mode) {
    if (mode > 3) return;
    // Seen on a Veazy and a Venty: mode 1 does not end boost.
    if (mode == 1 && _heaterMode >= 2) return;
    if (mode != 0 && _heaterMode == 0) _autoOffLeft = _autoOff;
    if (mode == 0) _autoOffLeft = Duration.zero;
    _heaterMode = mode;
  }

  int get _setpointTenths {
    final offset = switch (_heaterMode) {
      2 => _boost,
      3 => _boost + _superBoost,
      _ => 0,
    };
    return math.min(_baseTenths + offset * 10, _maxCelsius * 10);
  }

  bool get _reached =>
      _heaterMode != 0 && (_celsius - _setpointTenths / 10).abs() < 1;

  void _advance(Duration elapsed) {
    final seconds = elapsed.inMilliseconds / 1000;
    final goal = _heaterMode == 0 ? _ambient : _setpointTenths / 10;
    if (_celsius < goal) {
      _celsius = math.min(goal, _celsius + _heatPerSecond * seconds);
    } else {
      _celsius = math.max(goal, _celsius - _coolPerSecond * seconds);
    }
    if (_heaterMode == 0) return;
    _autoOffLeft -= elapsed;
    if (_autoOffLeft <= Duration.zero) _setHeaterMode(0);
    _sinceDrain += elapsed;
    if (_sinceDrain >= _batteryDrainEvery) {
      _sinceDrain = Duration.zero;
      _battery = math.max(5, _battery - 1);
    }
  }

  List<int> _statusPacket() {
    final target = _heaterMode >= 2 ? _setpointTenths : _baseTenths;
    return _packet(0x01)
      // 0x8000: no current temperature, as on the real devices.
      ..[2] = 0x00
      ..[3] = 0x80
      ..[4] = target & 0xFF
      ..[5] = (target >> 8) & 0xFF
      ..[6] = _boost
      ..[7] = _superBoost
      ..[8] = _battery
      ..[9] = math.min(255, _autoOffLeft.inSeconds)
      ..[11] = _heaterMode
      ..[14] = _settings | (_reached ? _reachedBit : 0);
  }

  List<int> _packet(int command) => List<int>.filled(20, 0)..[0] = command;

  void _reply(List<int> Function() build) {
    Timer(_replyDelay, () {
      if (_running) _notifications.add(build());
    });
  }
}
