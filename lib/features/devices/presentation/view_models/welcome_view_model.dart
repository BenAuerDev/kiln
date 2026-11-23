import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../app_settings/domain/repositories/app_settings_repository.dart';
import '../../../app_settings/domain/use_cases/complete_welcome_use_case.dart';
import '../../../app_settings/domain/use_cases/set_app_locale_use_case.dart';
import '../../domain/extensions/device_model_x.dart';
import '../../domain/models/discovered_device.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/use_cases/connect_device_use_case.dart';
import '../../domain/use_cases/start_device_scan_use_case.dart';
import '../../domain/use_cases/stop_device_scan_use_case.dart';
import '../navigation/devices_navigator.dart';
import 'welcome_step.dart';

class WelcomeViewModel {
  WelcomeViewModel({
    AppSettingsRepository? settings,
    ScanRepository? scan,
    StartDeviceScanUseCase? startScan,
    StopDeviceScanUseCase? stopScan,
    ConnectDeviceUseCase? connectDevice,
    CompleteWelcomeUseCase? completeWelcome,
    SetAppLocaleUseCase? setLocale,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    DevicesNavigator? navigator,
  }) : _settings = settings ?? sl<AppSettingsRepository>(),
       _scan = scan ?? sl<ScanRepository>(),
       _startScan = startScan ?? sl<StartDeviceScanUseCase>(),
       _stopScan = stopScan ?? sl<StopDeviceScanUseCase>(),
       _connectDevice = connectDevice ?? sl<ConnectDeviceUseCase>(),
       _completeWelcome = completeWelcome ?? sl<CompleteWelcomeUseCase>(),
       _setLocale = setLocale ?? sl<SetAppLocaleUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<DevicesNavigator>();

  final AppSettingsRepository _settings;
  final ScanRepository _scan;
  final StartDeviceScanUseCase _startScan;
  final StopDeviceScanUseCase _stopScan;
  final ConnectDeviceUseCase _connectDevice;
  final CompleteWelcomeUseCase _completeWelcome;
  final SetAppLocaleUseCase _setLocale;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final DevicesNavigator _navigator;

  final _step = signal<WelcomeStep>(WelcomeStep.intro);
  final _connectingId = signal<String?>(null);

  ReadonlySignal<WelcomeStep> get step => _step;

  /// Id of the device a connect is running for.
  ReadonlySignal<String?> get connectingId => _connectingId;
  ReadonlySignal<bool> get scanning => _scan.scanning;
  ReadonlySignal<List<DiscoveredDevice>> get found => _scan.results;

  late final Computed<String> languageCode = computed(
    () => _settings.localeCode.value ?? _l10n.locale.value.languageCode,
  );

  late final Computed<WelcomeScanState> scanState = computed(() {
    if (_scan.results.value.isNotEmpty) return WelcomeScanState.found;
    return _scan.scanning.value
        ? WelcomeScanState.looking
        : WelcomeScanState.nothing;
  });

  Future<void> selectLanguage(String code) async {
    if (code == languageCode.value) return;
    unawaited(_haptics.tick());
    _showError(await _setLocale(code));
  }

  Future<void> start() async {
    unawaited(_haptics.tick());
    _step.value = WelcomeStep.scan;
    await scanAgain();
  }

  Future<void> scanAgain() async => _showError(await _startScan());

  Future<void> connect(DiscoveredDevice device) async {
    if (_connectingId.value != null) return;
    _connectingId.value = device.id;
    final result = await _connectDevice(device.id);
    _connectingId.value = null;
    switch (result) {
      case Left(value: final error):
        unawaited(_haptics.warning());
        _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
      case Right(value: final known):
        unawaited(_haptics.success());
        final completed = await _completeWelcome();
        _showError(completed);
        // The router sends every route back to the welcome until it is done.
        if (completed.isLeft()) return;
        if (known.model.isSupported) {
          _navigator.goToDeviceHome(known.model);
        } else {
          _toast.show(
            _l10n.strings.devicesNotSupportedYet(known.model.displayName),
          );
          _navigator.goToDevices();
        }
    }
  }

  void openDemo() {
    unawaited(_haptics.tick());
    _navigator.openDemo();
  }

  Future<void> skip() async {
    unawaited(_stopScan());
    final completed = await _completeWelcome();
    _showError(completed);
    if (completed.isLeft()) return;
    _navigator.goToDevices();
  }

  void _showError(Either<AppError, Object?> result) {
    if (result case Left(value: final error)) {
      _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
    }
  }

  void dispose() {
    if (_scan.scanning.value) unawaited(_stopScan());
    languageCode.dispose();
    scanState.dispose();
  }
}
