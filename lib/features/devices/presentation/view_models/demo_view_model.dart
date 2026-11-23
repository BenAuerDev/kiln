import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../app_settings/domain/repositories/app_settings_repository.dart';
import '../../domain/models/device_model.dart';
import '../../domain/repositories/known_devices_repository.dart';
import '../../domain/services/welcome_gate.dart';
import '../../domain/use_cases/start_demo_use_case.dart';
import '../navigation/devices_navigator.dart';

/// The demo picker: one simulated device per supported model.
class DemoViewModel {
  DemoViewModel({
    AppSettingsRepository? settings,
    KnownDevicesRepository? knownDevices,
    StartDemoUseCase? startDemo,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    DevicesNavigator? navigator,
  }) : _settings = settings ?? sl<AppSettingsRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _startDemo = startDemo ?? sl<StartDemoUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<DevicesNavigator>();

  final AppSettingsRepository _settings;
  final KnownDevicesRepository _knownDevices;
  final StartDemoUseCase _startDemo;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final DevicesNavigator _navigator;

  final _startingModel = signal<DeviceModel?>(null);

  List<DeviceModel> get models => StartDemoUseCase.models;

  /// The model a demo is starting for.
  ReadonlySignal<DeviceModel?> get startingModel => _startingModel;

  Future<void> start(DeviceModel model) async {
    if (_startingModel.value != null) return;
    unawaited(_haptics.tick());
    _startingModel.value = model;
    final result = await _startDemo(model);
    _startingModel.value = null;
    result.match(
      (error) {
        unawaited(_haptics.warning());
        _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
      },
      (device) {
        unawaited(_haptics.success());
        _navigator.goToDeviceHome(device.model);
      },
    );
  }

  /// Without a screen to return to: the devices once past the welcome
  /// (same rule as the router's welcome gate), else the welcome.
  void back() => _navigator.back(
    fallback:
        WelcomeGate.isPast(
          welcomeCompleted: _settings.welcomeCompleted.value,
          devices: _knownDevices.devices.value,
        )
        ? RoutePaths.devices
        : RoutePaths.welcome,
  );

  void dispose() {}
}
