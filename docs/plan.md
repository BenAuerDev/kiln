# kiln: implementation plan (first pass)

Source of truth: `ARCHITECTURE.md` (incl. Addendum) and `docs/brief.md`.
Visual spec: `design/DESIGN.md`. Protocol: `docs/protocol.md`.

## Design decisions

1. **Portable navigation.** Portables get a 3-tab shell: **Control** (gauge,
   `Main.dc.html` with `device=veazy`: live temperature, heater, Boost button),
   **Setup** (the "set it once" ladder, `Veazy.dc.html`, priority screen) and
   **Devices**. The settings screen (`Finish.dc.html`) opens from the Setup
   header. Insights/Workflows tabs are left out until those features exist.
2. **Volcano navigation.** Bottom bar with Control (`Main.dc.html`) and Devices;
   Workflows and Insights join once they exist. No header Devices button on
   any device screen, the tab covers it.
3. **Mono finish.** Brief values are used (`#F9FAFB`, gradient `#4B5563 → #FFFFFF`)
   for dark. For light the `Main.dc.html` values (`#121212`, gradient
   `#C4C4BF → #121212`) are used because a white gradient end is invisible on a
   light background.
4. **Boost / superboost range** is 1–30 °C as in `Veazy.dc.html`; superboost
   stacks on top of boost (`t3 = base + boost + superboost`, each capped at
   the device max).
5. **Unverified writes** are disabled by a single allow-list in each feature's
   data layer (`<Feature>WriteSafety`). A disabled write returns
   `Left(AppError.writeNotVerified)` and the UI shows a toast. Boost (heater
   mode 2) was verified on a Veazy and a Venty on 2026-11-23 and is allowed;
   ending boost sends heater off, then on. Superboost stays disabled.
6. **Fonts** are bundled as static TTFs (OFL) in `assets/fonts/`.
7. **Kiln-only tokens** (gradient, glow, accent text, on-accent, raised
   surface, track) live in `KilnTokens`, provided by `KilnThemeScope` and read
   with `context.kiln`. Obers has no theme-extension mechanism. All hex values
   stay in `lib/core/theme/kiln_palette.dart`.

8. **Protocol corrections** from `docs/protocol.md` are applied:
   Volcano target is a 4-byte uint32, heater/pump write `0x00`, Find device is
   `0D 01`, vibration uses command `0x06`, settings writes carry a change mask
   in byte 15. The init sequence is `02` (abort in bootloader mode), `01 00`,
   `06 00…`, then a 500 ms `01 00` poll.
9. **"Match my device"** works for Veazy: after the session starts kiln sends
   the read-only identity request `05` and maps reply byte 18 (2 blue, 3 pink,
   4 orange → ember, else mono), as the official app does. Venty and Volcano
   report no colour, so they fall back to ember.
10. **Units:** the UI always shows °C in this pass, even if the device is set to °F.
11. **`flutter_blue_plus` licence:** `License.nonprofit` is passed on connect.
    kiln is open source and non-commercial.

## Folder tree

```
lib/
  main.dart                              bootstrap: WidgetsFlutterBinding, setupServiceLocator, runApp(KilnApp)
  app/
    kiln_app.dart                        HookWidget: OiApp.router + KilnThemeScope + l10n
    app_view_model.dart                  active finish, brightness tokens, locale; triggers auto-reconnect on start/resume
  core/
    service_locator.dart                 `final sl = GetIt.instance;` setupServiceLocator()
    ble/
      ble_client.dart                    thin flutter_blue_plus wrapper (scan, connect, discover, read, write, notify) by remoteId string
      ble_exceptions.dart                typed exceptions thrown by BleClient
      ble_scan_hit.dart                  plain scan result (id, name, rssi, serviceUuids)
      ble_connection_state.dart          enum connected/disconnected
      ble_error_mapper.dart              BleErrorMapper.toAppError
    errors/
      app_error.dart                     sealed AppError hierarchy
    formatters/
      temperature_formatter.dart         °C / °F display strings
    l10n/
      get_app_localizations.dart         getAppLocalizations(context)
      l10n_service.dart                  context-free AppLocalizations for view models
    router/
      app_router.dart                    GoRouter instance, rootNavigatorKey, redirect (welcome / devices / device home)
      app_routes.dart                    collects every feature's GoRoute subclasses
      route_paths.dart                   path constants
    services/
      haptics_service.dart               tick(), success(), warning()
      toast_service.dart                 show(message, level) through the root navigator context
      app_lifecycle_service.dart         ReadonlySignal<AppLifecycleState>
      system_locale_service.dart         ReadonlySignal<Locale> of the OS language
    theme/
      kiln_palette.dart                  ALL hex values (the theme file)
      kiln_theme.dart                    buildKilnTheme(finish, brightness) -> OiThemeData; text theme
      kiln_tokens.dart                   KilnTokens + KilnFinishTokens (no literals)
      kiln_theme_scope.dart              InheritedWidget holding the active finish
      build_context_x.dart               `context.kiln` (BuildContextX)
    widgets/
      kiln_gauge_painter.dart            270° gauge shared by Volcano and portables
  l10n/
    app_en.arb, app_de.arb               all strings; keys prefixed by feature (common*, devices*, portable*, volcano*, welcome*)
    generated/                           flutter gen-l10n output (committed)
  features/
    app_settings/                        locale override + "welcome seen" (shared_preferences)
    devices/
    portable/
    volcano/
```

Each feature follows the layout in `ARCHITECTURE.md`. Routes per feature live in
`presentation/<feature>_route.dart` as `GoRoute` subclasses.

## Shared contracts

### core
- `BleClient` (`registerLazySingleton`):
  - `Stream<List<BleScanHit>> scan({required List<String> serviceUuids, Duration timeout})`, `Future<void> stopScan()`
  - `Future<void> connect(String deviceId, {Duration timeout})`, `Future<void> disconnect(String deviceId)`
  - `Stream<BleConnectionState> connectionState(String deviceId)`
  - `Future<List<int>> read(String deviceId, String serviceUuid, String charUuid)`
  - `Future<void> write(String deviceId, String serviceUuid, String charUuid, List<int> value, {bool withResponse = true})`
  - `Stream<List<int>> subscribe(String deviceId, String serviceUuid, String charUuid)`
  - `Future<bool> get isSupported`, `Stream<bool> adapterOn`
  - throws `BleException` subclasses only.
- `AppError` (sealed): `bluetoothUnavailable`, `permissionDenied`, `deviceNotFound`,
  `connectionFailed`, `connectionLost`, `timeout`, `protocol`, `storage`,
  `writeNotVerified`, `notConnected`, `unknown`. Factory constructors are const.
- `HapticsService`: `tick()`, `success()`, `warning()`.
- `ToastService`: `show(String message, {ToastLevel level})`.
- `L10nService`: `AppLocalizations get strings` (follows the app locale).

### devices (domain)
- `enum DeviceModel { volcanoHybrid, venty, veazy, craftyPlus }`
- `enum DeviceFinish { ember, lava, blue, pink, mono }`
- `sealed FinishPreference` → `MatchDevice()` | `FixedFinish(DeviceFinish)`
- `KnownDevice { id, name, model, finishPreference, detectedFinish?, lastConnectedAt? }`
- `enum ConnectionStatus { disconnected, connecting, connected, reconnecting, unavailable }`
- `ConnectionRepository`: `ReadonlySignal<String?> activeDeviceId`, `ReadonlySignal<ConnectionStatus> status`, connect/disconnect, auto-reconnect job.
- `KnownDevicesRepository`: `ReadonlySignal<List<KnownDevice>> devices`, `ReadonlySignal<KnownDevice?> activeDevice` (computed with connection).
- Extensions: `DeviceModelX` (isPortable, isSupported, displayName),
  `KnownDeviceX.effectiveFinish` (preference → detected → ember).

### portable (domain)
- `enum HeaterMode { off, normal, boost, superboost }`
- `PortableSettings { fahrenheit, vibrateWhenReady, ecoCharge, ecoVoltage, boostVisualisation }`
- `PortableStatus { currentTemperature (double °C), targetTemperature (int °C), boostOffset, superBoostOffset, batteryPercent, charging, heaterMode, autoOffSeconds, settings }`
- `enum QuickSetup { flavour, balanced, full }`
- `PortableRepository`: `ReadonlySignal<PortableStatus?> status`, `startSession(deviceId)`, `stopSession()`,
  `setTargetTemperature(int)`, `setBoostOffset(int)`, `setSuperBoostOffset(int)`, `setHeaterMode(HeaterMode)`,
  `setSettings(PortableSettings)`, `findDevice()`, all `Future<Either<AppError, Unit>>`.

### volcano (domain)
- `VolcanoStatus { currentTemperature, targetTemperature, heaterOn, pumpOn, autoShutdown, fahrenheit, displayOnCooling, vibrationWhenReady }`
- `VolcanoRepository`: `ReadonlySignal<VolcanoStatus?> status`, `startSession`, `stopSession`, `setTargetTemperature`, `setHeater(bool)`, `setPump(bool)`.

## Use cases

| Feature | Use case | Notes |
|---|---|---|
| app_settings | `SetAppLocaleUseCase` | `null` = follow system |
| app_settings | `CompleteWelcomeUseCase` | |
| devices | `StartDeviceScanUseCase`, `StopDeviceScanUseCase` | filters to S&B devices |
| devices | `ConnectDeviceUseCase` | connects, remembers, sets active |
| devices | `DisconnectDeviceUseCase` | |
| devices | `ForgetDeviceUseCase` | disconnects if active |
| devices | `SetDeviceFinishUseCase` | per-device `FinishPreference` |
| devices | `ReconnectLastDeviceUseCase` | app start / resume |
| portable | `StartPortableSessionUseCase`, `StopPortableSessionUseCase` | |
| portable | `AdjustBaseTemperatureUseCase(delta)` | clamp 40–210 |
| portable | `AdjustBoostOffsetUseCase(delta)`, `AdjustSuperBoostOffsetUseCase(delta)` | clamp 1–30 |
| portable | `ApplyQuickSetupUseCase(QuickSetup)` | composer |
| portable | `TogglePortableHeaterUseCase`, `TogglePortableBoostUseCase` | boost ends with heater off, then on (mode 1 alone does not end it) |
| portable | `UpdatePortableSettingsUseCase` | |
| portable | `FindPortableDeviceUseCase` | |
| volcano | `StartVolcanoSessionUseCase`, `StopVolcanoSessionUseCase` | |
| volcano | `AdjustVolcanoTargetUseCase(delta)`, `SetVolcanoTargetUseCase` | clamp 40–230 |
| volcano | `ToggleVolcanoHeaterUseCase`, `ToggleVolcanoPumpUseCase` | |

Domain services: `TemperatureClampService` (core rule per model),
`PortableLadderService` (t1/t2/t3, scale positions, preset matching),
`ScanFilterService` (name/service → `DeviceModel`).

## DI registrations

```
core:          sl<BleClient> (lazy), sl<SharedPreferencesAsync> (lazy), HapticsService, ToastService,
               L10nService, AppLifecycleService (lazy singletons), AppViewModel (factory)
app_settings:  AppSettingsDataSource, AppSettingsRepository (lazy); SetAppLocaleUseCase, CompleteWelcomeUseCase (factory)
devices:       KnownDevicesDataSource, DeviceScanDataSource, DeviceConnectionDataSource (lazy);
               KnownDevicesRepository, ScanRepository, ConnectionRepository (lazy);
               all devices use cases (factory); WelcomeViewModel, DevicesViewModel (factory)
portable:      PortableBleDataSource (lazy); PortableRepository (lazy); portable use cases (factory);
               PortableControlViewModel, PortableSetupViewModel, PortableSettingsViewModel (factory)
volcano:       VolcanoBleDataSource (lazy); VolcanoRepository (lazy); volcano use cases (factory); VolcanoControlViewModel (factory)
```
