import 'dart:async';
import 'dart:ui';

import 'package:signals_flutter/signals_flutter.dart';

import '../core/l10n/l10n_service.dart';
import '../core/service_locator.dart';
import '../core/services/app_lifecycle_service.dart';
import '../core/services/system_locale_service.dart';
import '../core/theme/kiln_palette.dart';
import '../core/theme/kiln_tokens.dart';
import '../features/app_settings/domain/repositories/app_settings_repository.dart';
import '../features/devices/domain/extensions/known_device_x.dart';
import '../features/devices/domain/repositories/known_devices_repository.dart';
import '../features/devices/domain/use_cases/reconnect_last_device_use_case.dart';
import '../features/devices/presentation/extensions/device_finish_x.dart';
import '../features/portable/domain/repositories/portable_repository.dart';
import '../features/portable/domain/use_cases/set_portable_polling_use_case.dart';
import '../features/portable/domain/use_cases/sync_portable_reconnect_use_case.dart';

class AppViewModel {
  AppViewModel({
    AppSettingsRepository? settings,
    KnownDevicesRepository? knownDevices,
    AppLifecycleService? lifecycle,
    SystemLocaleService? systemLocale,
    L10nService? l10n,
    ReconnectLastDeviceUseCase? reconnectLastDevice,
    SetPortablePollingUseCase? setPortablePolling,
    PortableRepository? portable,
    SyncPortableReconnectUseCase? syncPortableReconnect,
  }) : _settings = settings ?? sl<AppSettingsRepository>(),
       _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _lifecycle = lifecycle ?? sl<AppLifecycleService>(),
       _systemLocale = systemLocale ?? sl<SystemLocaleService>(),
       _l10n = l10n ?? sl<L10nService>(),
       _reconnectLastDevice =
           reconnectLastDevice ?? sl<ReconnectLastDeviceUseCase>(),
       _setPortablePolling =
           setPortablePolling ?? sl<SetPortablePollingUseCase>(),
       _portable = portable ?? sl<PortableRepository>(),
       _syncPortableReconnect =
           syncPortableReconnect ?? sl<SyncPortableReconnectUseCase>() {
    _effects
      ..add(
        effect(() {
          final preferred = switch (locale.value) {
            final Locale override => [override],
            null => _systemLocale.locales.value,
          };
          untracked(() => _l10n.updateLocales(preferred));
        }),
      )
      ..add(
        effect(() {
          switch (_lifecycle.state.value) {
            case AppLifecycleState.resumed:
              untracked(() {
                _setPortablePolling(active: true);
                unawaited(_reconnectLastDevice());
              });
            case AppLifecycleState.hidden || AppLifecycleState.paused:
              untracked(() => _setPortablePolling(active: false));
            case AppLifecycleState.inactive || AppLifecycleState.detached:
              break;
          }
        }),
      )
      ..add(
        effect(() {
          // A null status means the session just ended; keep the last
          // decision so the drop that ended it is judged by it.
          final status = _portable.status.value;
          if (status != null) untracked(() => _syncPortableReconnect(status));
        }),
      );
  }

  final AppSettingsRepository _settings;
  final KnownDevicesRepository _knownDevices;
  final AppLifecycleService _lifecycle;
  final SystemLocaleService _systemLocale;
  final L10nService _l10n;
  final ReconnectLastDeviceUseCase _reconnectLastDevice;
  final SetPortablePollingUseCase _setPortablePolling;
  final PortableRepository _portable;
  final SyncPortableReconnectUseCase _syncPortableReconnect;
  final List<void Function()> _effects = [];

  /// Drives the router redirect away from the welcome flow.
  ReadonlySignal<bool> get welcomeCompleted => _settings.welcomeCompleted;

  late final Computed<Locale?> locale = computed(() {
    final code = _settings.localeCode.value;
    return code == null ? null : Locale(code);
  });

  late final Computed<KilnFinishTokens> finish = computed(
    () =>
        _knownDevices.activeDevice.value?.effectiveFinish.tokens ??
        KilnPalette.ember,
  );

  /// Follows the language the app is rendered in.
  late final Computed<String> title = computed(() => _l10n.strings.appTitle);

  void dispose() {
    for (final dispose in _effects) {
      dispose();
    }
    locale.dispose();
    finish.dispose();
    title.dispose();
  }
}
