import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../domain/extensions/device_model_x.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/discovered_device.dart';
import '../../domain/models/known_device.dart';
import '../../domain/models/known_device_entry.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/repositories/known_devices_repository.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/services/device_list_service.dart';
import '../../domain/use_cases/connect_device_use_case.dart';
import '../../domain/use_cases/disconnect_device_use_case.dart';
import '../../domain/use_cases/forget_device_use_case.dart';
import '../../domain/use_cases/start_device_scan_use_case.dart';
import '../../domain/use_cases/stop_device_scan_use_case.dart';
import '../navigation/devices_navigator.dart';

class DevicesViewModel {
  DevicesViewModel({
    KnownDevicesRepository? knownDevices,
    ConnectionRepository? connection,
    ScanRepository? scan,
    DeviceListService? listService,
    StartDeviceScanUseCase? startScan,
    StopDeviceScanUseCase? stopScan,
    ConnectDeviceUseCase? connectDevice,
    DisconnectDeviceUseCase? disconnectDevice,
    ForgetDeviceUseCase? forgetDevice,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    DevicesNavigator? navigator,
    DateTime Function()? clock,
  }) : _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _connection = connection ?? sl<ConnectionRepository>(),
       _scan = scan ?? sl<ScanRepository>(),
       _listService = listService ?? sl<DeviceListService>(),
       _startScan = startScan ?? sl<StartDeviceScanUseCase>(),
       _stopScan = stopScan ?? sl<StopDeviceScanUseCase>(),
       _connectDevice = connectDevice ?? sl<ConnectDeviceUseCase>(),
       _disconnectDevice = disconnectDevice ?? sl<DisconnectDeviceUseCase>(),
       _forgetDevice = forgetDevice ?? sl<ForgetDeviceUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<DevicesNavigator>(),
       _clock = clock ?? DateTime.now;

  final KnownDevicesRepository _knownDevices;
  final ConnectionRepository _connection;
  final ScanRepository _scan;
  final DeviceListService _listService;
  final StartDeviceScanUseCase _startScan;
  final StopDeviceScanUseCase _stopScan;
  final ConnectDeviceUseCase _connectDevice;
  final DisconnectDeviceUseCase _disconnectDevice;
  final ForgetDeviceUseCase _forgetDevice;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final DevicesNavigator _navigator;
  final DateTime Function() _clock;

  final _connectingId = signal<String?>(null);
  final _confirmingForgetId = signal<String?>(null);

  ReadonlySignal<bool> get scanning => _scan.scanning;

  /// Id of the device a connect is running for.
  ReadonlySignal<String?> get connectingId => _connectingId;

  /// Id of the device whose forget button waits for confirmation.
  ReadonlySignal<String?> get confirmingForgetId => _confirmingForgetId;

  late final Computed<List<KnownDeviceEntry>> knownDevices = computed(
    () => _listService.knownEntries(
      devices: _knownDevices.devices.value,
      activeDeviceId: _connection.activeDeviceId.value,
      status: _connection.status.value,
      now: _clock(),
    ),
  );

  late final Computed<List<DiscoveredDevice>> nearby = computed(
    () => _listService.nearbyUnknown(
      discovered: _scan.results.value,
      known: _knownDevices.devices.value,
    ),
  );

  late final Computed<bool> activeConnected = computed(
    () =>
        _knownDevices.activeDevice.value != null &&
        _connection.status.value == ConnectionStatus.connected,
  );

  /// The header's back button leads to the active device's home.
  late final Computed<bool> canGoBack = computed(
    () =>
        activeConnected.value &&
        _knownDevices.activeDevice.value!.model.isSupported,
  );

  Future<void> scan() async => _showError(await _startScan());

  Future<void> openKnown(KnownDeviceEntry entry) async {
    if (entry.isActive && entry.status == ConnectionStatus.connected) {
      _goHome(entry.device);
      return;
    }
    await _connect(entry.device.id);
  }

  Future<void> pair(DiscoveredDevice device) => _connect(device.id);

  void openDemo() {
    unawaited(_haptics.tick());
    _navigator.openDemo();
  }

  void goBack() {
    final active = _knownDevices.activeDevice.value;
    if (active != null) _goHome(active);
  }

  Future<void> disconnect() async {
    unawaited(_haptics.tick());
    _showError(await _disconnectDevice());
  }

  void askForget(String deviceId) {
    unawaited(_haptics.tick());
    _confirmingForgetId.value = deviceId;
  }

  void cancelForget() => _confirmingForgetId.value = null;

  Future<void> confirmForget(String deviceId) async {
    _confirmingForgetId.value = null;
    final device = _knownDevices.byId(deviceId);
    final result = await _forgetDevice(deviceId);
    switch (result) {
      case Left(value: final error):
        unawaited(_haptics.warning());
        _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
      case Right():
        unawaited(_haptics.success());
        if (device != null) {
          _toast.show(_l10n.strings.devicesForgotten(device.model.displayName));
        }
    }
  }

  Future<void> _connect(String deviceId) async {
    if (_connectingId.value != null) return;
    unawaited(_haptics.tick());
    _connectingId.value = deviceId;
    final result = await _connectDevice(deviceId);
    _connectingId.value = null;
    switch (result) {
      case Left(value: final error):
        unawaited(_haptics.warning());
        _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
      case Right(value: final device):
        unawaited(_haptics.success());
        _goHome(device);
    }
  }

  void _goHome(KnownDevice device) {
    if (device.model.isSupported) {
      _navigator.goToDeviceHome(device.model);
    } else {
      _toast.show(
        _l10n.strings.devicesNotSupportedYet(device.model.displayName),
      );
    }
  }

  void _showError(Either<AppError, Object?> result) {
    if (result case Left(value: final error)) {
      _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
    }
  }

  void dispose() {
    if (_scan.scanning.value) unawaited(_stopScan());
    knownDevices.dispose();
    nearby.dispose();
    canGoBack.dispose();
    activeConnected.dispose();
  }
}
