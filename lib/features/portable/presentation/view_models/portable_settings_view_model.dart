import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/service_locator.dart';
import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/domain/models/device_finish.dart';
import '../../../devices/domain/models/finish_preference.dart';
import '../../../devices/domain/models/known_device.dart';
import '../../../devices/domain/use_cases/forget_device_use_case.dart';
import '../../../devices/domain/use_cases/set_device_finish_use_case.dart';
import '../../domain/models/portable_settings.dart';
import '../../domain/models/portable_status.dart';
import '../../domain/use_cases/find_portable_device_use_case.dart';
import '../../domain/use_cases/update_portable_settings_use_case.dart';
import '../navigation/portable_navigator.dart';
import 'portable_session_binding.dart';

/// Device settings, app theme per device and forgetting the device.
class PortableSettingsViewModel {
  PortableSettingsViewModel({
    PortableSessionBinding? session,
    FindPortableDeviceUseCase? findDevice,
    UpdatePortableSettingsUseCase? updateSettings,
    SetDeviceFinishUseCase? setFinish,
    ForgetDeviceUseCase? forgetDevice,
    PortableNavigator? navigator,
    this.findingDuration = const Duration(seconds: 3),
  }) : _session = session ?? sl<PortableSessionBinding>(),
       _findDevice = findDevice ?? sl<FindPortableDeviceUseCase>(),
       _updateSettings = updateSettings ?? sl<UpdatePortableSettingsUseCase>(),
       _setFinish = setFinish ?? sl<SetDeviceFinishUseCase>(),
       _forgetDevice = forgetDevice ?? sl<ForgetDeviceUseCase>(),
       _navigator = navigator ?? sl<PortableNavigator>();

  final PortableSessionBinding _session;
  final FindPortableDeviceUseCase _findDevice;
  final UpdatePortableSettingsUseCase _updateSettings;
  final SetDeviceFinishUseCase _setFinish;
  final ForgetDeviceUseCase _forgetDevice;
  final PortableNavigator _navigator;

  /// How long the "Buzzing your …" state stays after a find request.
  final Duration findingDuration;

  final _finding = signal(false);
  Timer? _findingTimer;

  List<DeviceFinish> get finishes => DeviceFinish.values;

  ReadonlySignal<PortableStatus?> get status => _session.status;

  ReadonlySignal<KnownDevice?> get device => _session.device;

  ReadonlySignal<String> get deviceName => _session.deviceName;

  ReadonlySignal<bool> get controlsEnabled => _session.controlsEnabled;

  ReadonlySignal<bool> get finding => _finding;

  late final Computed<PortableSettings?> settings = computed(
    () => _session.status.value?.settings,
  );

  Future<void> findDevice() {
    _session.tick();
    return _session.write(() async {
      (await _findDevice()).match(_session.showError, (_) {
        _findingTimer?.cancel();
        _finding.value = true;
        _findingTimer = Timer(findingDuration, () => _finding.value = false);
      });
    });
  }

  Future<void> setChargeLimit(bool on) =>
      _update((s) => s.copyWith(ecoCharge: on));

  Future<void> setBatterySaver(bool on) =>
      _update((s) => s.copyWith(ecoVoltage: on));

  Future<void> setVibrateWhenReady(bool on) =>
      _update((s) => s.copyWith(vibrateWhenReady: on));

  Future<void> setBoostOnLeds(bool on) =>
      _update((s) => s.copyWith(boostVisualisation: on));

  Future<void> setFahrenheit(bool on) =>
      _update((s) => s.copyWith(fahrenheit: on));

  Future<void> selectFinish(FinishPreference preference) async {
    final device = _session.device.value;
    if (device == null || device.finishPreference == preference) return;
    _session.tick();
    (await _setFinish(device.id, preference)).match(_session.showError, (_) {});
  }

  Future<void> forgetDevice() async {
    final device = _session.device.value;
    if (device == null) return;
    if (!await _navigator.confirmForget(device.model.displayName)) return;
    (await _forgetDevice(
      device.id,
    )).match(_session.showError, (_) => _navigator.goToDevices());
  }

  void back() => _navigator.back();

  void dispose() {
    _findingTimer?.cancel();
    settings.dispose();
    _session.dispose();
  }

  Future<void> _update(PortableSettings Function(PortableSettings) change) {
    _session.tick();
    // Built inside the job so a queued change starts from what the previous
    // write left behind instead of reverting it.
    return _session.write(() async {
      final current = settings.value;
      if (current == null) return;
      final next = change(current);
      if (next == current) return;
      (await _updateSettings(
        next,
      )).match(_session.showError, (_) => _session.confirmSaved());
    });
  }
}
