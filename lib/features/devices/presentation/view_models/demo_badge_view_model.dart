import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../app_settings/domain/repositories/app_settings_repository.dart';
import '../../domain/extensions/known_device_x.dart';
import '../../domain/repositories/known_devices_repository.dart';
import '../../domain/services/welcome_gate.dart';
import '../../domain/use_cases/leave_demo_use_case.dart';
import '../navigation/devices_navigator.dart';

/// State of the "Leave demo" badge in device headers. Everything it shows
/// lives in repository signals, so each badge may own an instance.
class DemoBadgeViewModel {
  DemoBadgeViewModel({
    KnownDevicesRepository? knownDevices,
    AppSettingsRepository? settings,
    LeaveDemoUseCase? leaveDemo,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    DevicesNavigator? navigator,
  }) : _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _settings = settings ?? sl<AppSettingsRepository>(),
       _leaveDemo = leaveDemo ?? sl<LeaveDemoUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<DevicesNavigator>();

  final KnownDevicesRepository _knownDevices;
  final AppSettingsRepository _settings;
  final LeaveDemoUseCase _leaveDemo;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final DevicesNavigator _navigator;

  late final Computed<bool> visible = computed(
    () => _knownDevices.activeDevice.value?.isDemo ?? false,
  );

  Future<void> leave() async {
    unawaited(_haptics.tick());
    final result = await _leaveDemo();
    result.match(
      (error) =>
          _toast.show(error.message(_l10n.strings), level: ToastLevel.error),
      // Same rule as the router's welcome gate, once the demo is gone.
      (_) =>
          WelcomeGate.isPast(
            welcomeCompleted: _settings.welcomeCompleted.value,
            devices: _knownDevices.devices.value,
          )
          ? _navigator.goToDevices()
          : _navigator.goToWelcome(),
    );
  }

  void dispose() => visible.dispose();
}
