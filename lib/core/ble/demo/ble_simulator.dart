import 'dart:async';

import '../ble_connection_state.dart';
import '../ble_exceptions.dart';
import 'demo_device_ids.dart';
import 'simulated_portable.dart';
import 'simulated_volcano.dart';

/// The demo devices behind `BleClient`: same calls, same exceptions, no
/// radio. Each demo device keeps its state for the lifetime of the app, so
/// leaving and re-entering the demo finds it as it was left.
class BleSimulator {
  BleSimulator({
    this._connectDelay = const Duration(milliseconds: 600),
    SimulatedPortable? venty,
    SimulatedPortable? veazy,
    SimulatedVolcano? volcano,
  }) : _venty = venty ?? SimulatedPortable(isVeazy: false),
       _veazy = veazy ?? SimulatedPortable(isVeazy: true),
       _volcano = volcano ?? SimulatedVolcano();

  final Duration _connectDelay;
  final SimulatedPortable _venty;
  final SimulatedPortable _veazy;
  final SimulatedVolcano _volcano;

  final Map<String, BleConnectionState> _states = {};
  final _stateChanges =
      StreamController<(String, BleConnectionState)>.broadcast();

  Future<void> connect(String deviceId) async {
    _ensureKnown(deviceId);
    await Future<void>.delayed(_connectDelay);
    switch (deviceId) {
      case DemoDeviceIds.volcano:
        _volcano.start();
      default:
        _portable(deviceId).start();
    }
    _setState(deviceId, BleConnectionState.connected);
  }

  Future<void> disconnect(String deviceId) async {
    _ensureKnown(deviceId);
    switch (deviceId) {
      case DemoDeviceIds.volcano:
        _volcano.stop();
      default:
        _portable(deviceId).stop();
    }
    _setState(deviceId, BleConnectionState.disconnected);
  }

  /// Emits the current state first, like flutter_blue_plus.
  Stream<BleConnectionState> connectionState(String deviceId) =>
      Stream.multi((controller) {
        controller.add(_state(deviceId));
        final subscription = _stateChanges.stream
            .where((change) => change.$1 == deviceId)
            .listen((change) => controller.add(change.$2));
        controller.onCancel = subscription.cancel;
      });

  Future<List<int>> read(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    _ensureConnected(deviceId);
    if (deviceId != DemoDeviceIds.volcano) {
      // The Venty/Veazy characteristic is write + notify only.
      throw BleOperationException('demo: $characteristicUuid is not readable');
    }
    return _volcano.read(serviceUuid, characteristicUuid);
  }

  Future<void> write(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
    List<int> value,
  ) async {
    _ensureConnected(deviceId);
    if (deviceId == DemoDeviceIds.volcano) {
      _volcano.write(serviceUuid, characteristicUuid, value);
      return;
    }
    _checkPortable(serviceUuid, characteristicUuid);
    _portable(deviceId).write(value);
  }

  Future<void> enableNotifications(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async => _checkSubscribable(deviceId, serviceUuid, characteristicUuid);

  /// Fails on listen when the device is not connected or has no such
  /// characteristic, like the radio does.
  Stream<List<int>> subscribe(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) => Stream.multi((controller) {
    try {
      _checkSubscribable(deviceId, serviceUuid, characteristicUuid);
    } on BleException catch (e) {
      controller
        ..addError(e)
        ..close();
      return;
    }
    final source = deviceId == DemoDeviceIds.volcano
        ? _volcano.notifications(characteristicUuid)
        : _portable(deviceId).notifications;
    final subscription = source.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  void _checkSubscribable(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) {
    _ensureConnected(deviceId);
    if (deviceId == DemoDeviceIds.volcano) {
      _volcano.checkReadable(serviceUuid, characteristicUuid);
    } else {
      _checkPortable(serviceUuid, characteristicUuid);
    }
  }

  void _checkPortable(String serviceUuid, String characteristicUuid) {
    if (serviceUuid != SimulatedPortable.serviceUuid ||
        characteristicUuid != SimulatedPortable.characteristicUuid) {
      throw BleCharacteristicNotFoundException('demo: $characteristicUuid');
    }
  }

  SimulatedPortable _portable(String deviceId) =>
      deviceId == DemoDeviceIds.veazy ? _veazy : _venty;

  BleConnectionState _state(String deviceId) =>
      _states[deviceId] ?? BleConnectionState.disconnected;

  void _setState(String deviceId, BleConnectionState state) {
    _states[deviceId] = state;
    _stateChanges.add((deviceId, state));
  }

  void _ensureKnown(String deviceId) {
    const known = {
      DemoDeviceIds.volcano,
      DemoDeviceIds.venty,
      DemoDeviceIds.veazy,
    };
    if (!known.contains(deviceId)) {
      throw BleConnectionException('unknown demo device: $deviceId');
    }
  }

  void _ensureConnected(String deviceId) {
    _ensureKnown(deviceId);
    if (_state(deviceId) != BleConnectionState.connected) {
      throw BleConnectionException('not connected: $deviceId');
    }
  }
}
