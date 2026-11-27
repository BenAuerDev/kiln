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
   ending boost sends heater off, then on. Superboost (heater mode 3) was
   verified on a Veazy and a Venty later the same day and is allowed too (second pass,
   step 3).
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

---

# Second pass: plan

Order and ground rules: releases, demo mode, superboost, workflows and ramp
profiles, background connection, widgets, insights, sharing, presence. Each
step ends with `dart format`, `flutter analyze`, `flutter test`, a review by
someone who did not write the code, and a suggested commit. Items marked
**owner** need a decision or a hardware test before the step can finish.

## 1. Releases

- `android/app/build.gradle.kts` reads `android/key.properties` (git-ignored,
  like `*.jks` and `*.keystore`). Without it, release builds fall back to the
  debug key with a Gradle warning, so contributors can still build.
- `.github/workflows/release.yml` runs on a pushed `v*` tag: checks the tag
  against `pubspec.yaml`, runs format/analyze/test, writes the keystore from
  secrets into `$RUNNER_TEMP`, builds the APK, refuses a debug-signed or
  unsigned APK (`apksigner`; v2/v3 signatures only, keytool cannot read them),
  and publishes `kiln-vX.Y.Z.apk` plus its SHA-256 with `gh release create`.
  No third-party release action; Flutter is pinned to the local version.
- One universal APK (no per-ABI split): simplest for friends to install.
- Secrets: `KILN_KEYSTORE_BASE64`, `KILN_KEYSTORE_PASSWORD`, `KILN_KEY_ALIAS`,
  `KILN_KEY_PASSWORD`. README "Releases" has the keystore and `gh secret`
  commands and the release steps.

## 2. Demo mode

**Approach: a simulated peripheral inside `BleClient`.** Device ids starting
with `demo:` (`demo:volcano`, `demo:venty`, `demo:veazy`) are routed by
`BleClient` to `BleSimulator` (`lib/core/ble/demo/`) instead of
flutter_blue_plus. Everything above `BleClient` is unchanged: data sources,
codecs, `WriteSafety`, repositories, reconnect rules and UI all run for real.

- Why here: no abstract class plus implementation, no second data source or
  repository per feature, and the demo exercises the real protocol code, so it
  doubles as an end-to-end check of packets and the allow-list.
- The simulator is a fake *device*: it answers bytes per `docs/protocol.md` and
  is written independently of the app's encoders (it does not import
  `features/`), so a bug in an encoder is not mirrored by the fake.
  - Venty/Veazy: answers `02` (application running), `01 00` status, `06`
    settings, `05` identity (Veazy reports blue); applies `01` writes by their
    mask; heater modes 1–3 heat towards base / base+boost / base+boost+super
    and set the "reached" bit; battery drains slowly while heating; current
    temperature stays `0x8000` like the real devices.
  - Volcano: temperature notifications in ~4 °C steps like the real one, but
    sped up (about 30 s to 185 °C); heater/pump on/off; register 1 bits.
  - Unknown or not-allow-listed writes never reach it, as with real devices.
- Demo devices are never persisted: `KnownDevicesRepository` keeps them in a
  separate in-memory list, they never become the "last device" and are never
  auto-reconnected. Leaving the demo disconnects and removes them.
- Entry: "Try the demo" on the welcome screen and the devices screen, then a
  choice of Volcano Hybrid, Venty or Veazy (`/demo`). Device screens show a
  "Demo ×" badge in the header that leaves the demo; the devices list labels
  the demo device "Demo".
- Starting a demo from the welcome screen does not complete the welcome: the
  router lets the app past the welcome while any device is known (saved or
  demo). Leaving a demo with no saved device returns to the welcome, so the
  Bluetooth explainer still comes before the system permission prompt.
- Leaving the demo does not count as a disconnect by the user, so the last
  real device is reconnected on the next resume as usual.
- The README screenshot tool keeps its mocks for now (deterministic pixels);
  it can move to the demo later if the mocks get in the way.

## 3. Superboost (done)

- Verified on a Veazy and a Venty on 2026-11-23 with an opt-in
  `--dart-define` build and the debug log (docs/protocol.md, Superboost). The
  switch is gone and `heaterSuperBoost` is on `PortableWriteSafety`'s
  allow-list.
- The Boost button cycles boost → superboost → off, then on at base.

## 4. Volcano workflows and portable ramp profiles

- Domain: `Workflow { id, name, steps, builtIn }`, sealed `WorkflowStep`:
  `HeatTo(°C)` (wait until reached, then haptic "buzz"), `Hold(duration)`,
  `Air(duration)` (pump on, then off), `HeaterOff`. Presets per
  `Workflow.dc.html` ("Three-balloon session" and a couple more); user
  workflows stored as JSON in shared_preferences.
- `WorkflowRunRepository` holds the run (workflow, step index, step start,
  progress, finished/stopped) in signals and owns the job (Addendum 1).
  `StartWorkflowRunUseCase`, `SkipWorkflowStepUseCase`,
  `StopWorkflowRunUseCase` drive it; step completion and progress are pure
  functions in `WorkflowStepService` (tested). Temperatures are clamped by the
  existing Volcano rules. A dropped connection pauses the run, stop turns heater
  and pump off.
- Ramp profiles (Venty/Veazy): `RampProfile { name, start, step °C, every
  duration, end }`; `PortableRampRepository` runs it. While boost or
  superboost is active, target writes are blocked, so the ramp waits and
  resumes with the next due step after boost ends. A manual base change stops
  the ramp.
- Screens: Volcano gets a Workflows tab (list, run screen per mockup, editor);
  portables get the ramp on the Setup tab.
- Until step 5 exists, a run only continues while kiln is open.

**Status:** Volcano workflows done (feature `workflows`): presets (three
balloons, one balloon, flavour ladder) and user workflows in
shared_preferences, run screen per `Workflow.dc.html`, editor, third Volcano
tab. Steps are heat (wait until reached, haptic buzz), hold and air; the last
step can turn the heater off. A run pauses while the Volcano is not connected
and resumes where it stopped; Stop turns pump and heater off. Ramp profiles for
Venty/Veazy followed in the feature `ramps`: three presets (Gentle 170→190 °C
+5 every 2 min, Classic 180→200 °C +5 every 90 s, Quick 185→205 °C +10 every
minute) on the Setup tab, a banner on the Control tab while one runs. Only the
verified target write is used (clamped 40–210 °C) plus heater on at the start.
A due step waits while boosting and is written when boost ends; a manual base
change, heater off or another device stops the ramp. Custom ramps followed:
your own start, end, step (1–25 °C) and interval (15 s–10 min), made from the
chosen ramp with "New ramp" on the ramp card and edited or deleted in an
editor like the workflow one; stored in shared preferences (`ramps.v1`).

## 5. Background connection and notifications (Android)

Proposal (**owner** to confirm):
- An own Kotlin foreground service (`foregroundServiceType="connectedDevice"`),
  no plugin. It holds no logic: it keeps the process at foreground priority and
  shows the notification. All BLE, workflow and reconnect logic stays in Dart
  in the main isolate, which keeps running while the process lives.
- A method channel (`dev.bespokecode.kiln/background`) starts, updates and
  stops the service. `BackgroundSessionUseCase` starts it only while a heater
  is on (Volcano heater, portable mode ≥ 1) and stops it when the heater goes
  off or the link drops for good. Existing reconnect rules stay as they are.
- Notification: device and temperature (target on portables), "ready"
  alert as a separate high-priority notification once per heat-up
  (`Live.dc.html`). Android 13+ asks for `POST_NOTIFICATIONS` the first time.
- Swiping kiln away from recents ends the service and the connection
  (`stopWithTask`). Keeping Dart alive after that would need a cached engine;
  not worth it now.

**Status:** built (feature `background`, `KilnSessionService.kt`). The service
runs while the active device heats (portable heater on, Volcano heater on or a
workflow running on it); the notification shows device and temperature, the
workflow step or the battery; a "ready" alert fires once per heat-up while
kiln is not in front. The Venty/Veazy poll now pauses in the background only
while nothing heats. Android 12+ refuses to start a foreground service from
the background, so a heater switched on at the device while kiln is hidden
starts the service when kiln is opened. **owner**: test on the phone.

## 6. Home-screen widgets (Android first)

- Own `AppWidgetProvider`s with RemoteViews (no plugin). Dart writes the last
  known values into a small SharedPreferences file through the same method
  channel and asks the widgets to refresh.
- Veazy/Venty widget: battery, base / boost / superboost. Works without the
  service (last known values, timestamp).
- Volcano widget: live temperature and target while the service runs; Heat and
  Air buttons send an intent that the service forwards to Dart. Without a
  running service they open kiln.

**Status:** built (feature `home_widgets`). Storage and refresh go through
the `home_widget` package (BSD-3-Clause): Dart saves one JSON string per
widget into its `HomeWidgetPreferences` (texts from the `.arb` files, colours
as ARGB from the finish's dark tokens) plus a live flag each, then calls
`updateWidget`; `PortableWidgetProvider` and `VolcanoWidgetProvider` extend
`HomeWidgetProvider` and draw RemoteViews. `HomeWidgetsViewModel` (app-level,
like `BackgroundViewModel`) pushes changes only, never for demo devices.

- Venty/Veazy widget, built like the Volcano one: a battery
  ring holding the device's line drawing (device_glyph_painter.dart, drawn
  in Kotlin), live status, the Setup tab's ladder bar with base / boost /
  superboost, and Heat / Boost (Boost steps boost → superboost → off like
  the app button). After a disconnect it keeps the last values, the ring
  turns grey and a tap opens kiln. No timestamp yet.
- Volcano widget (the wide card of `Widgets.dc.html`): gauge (a bitmap drawn
  in Kotlin), temperature, status, Heat and Air.
- Both are 4×1 by default: one row with gauge or ring, name, status (and
  the three temperatures on the Venty/Veazy) and the two buttons. Resized
  to two rows they show the full card. Android 12+ picks the layout as the
  widget is resized; below that the provider picks it from the size.
- Each widget is live while its kind of device (real, not demo) is
  connected *and* kiln's Flutter engine runs (`KilnWidgets.dispatcher`,
  set by `MainActivity`). Android can kill kiln without Dart noticing, so
  Kotlin takes both widgets offline itself (`KilnWidgets.goOffline`) when
  the engine starts or goes, and when the service ends without Dart asking (a
  swipe from recents). A low-memory kill while nothing heats leaves the
  last drawing until the next tap, which then redraws it offline.
- Change from the plan above: the buttons (both widgets) do not go
  through the service. They send a broadcast to their provider, which
  hands them to Dart (`KilnWidgets.onButton`)
  over the `dev.bespokecode.kiln/widgets` channel and the
  `HandleHomeWidgetActionUseCase` (same toggles as the control screens). So
  they also work while kiln runs in the background with the heater off; the
  receiver holds the broadcast (`goAsync`) until Dart has sent the write, so
  a cached, frozen kiln wakes up for it. While kiln is cached and nothing
  heats, Android may freeze it again, and the widget then lags behind the
  device until the next tap or until kiln is opened.
  home_widget's own interactivity callback was not used: it runs in a
  separate isolate without the Bluetooth link. Offline, a tap anywhere opens
  kiln.
- **owner**: test on the phone. Heat from the widget while kiln is in the
  background and nothing heats starts the foreground service from the
  background; Android allows that after a widget tap, but this needs a real
  check. Also check the widget sizes on your launcher (labels shrink to fit
  from Android 8).
- home_widget 0.10.0 brings Glance and WorkManager along, which add the
  `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK` and `ACCESS_NETWORK_STATE`
  permissions and a boot receiver to the merged manifest. kiln uses none of
  them.

## 7. Sessions and insights

- A session = heater on → heater off (or link lost), per device: start, end,
  target(s) used, boost/superboost use, time to "ready". Recorded by a
  `SessionRecorderRepository` watching the device repositories; stored as JSON
  in shared_preferences, pruned to 12 months. Demo sessions are not recorded.
- Insights screen per `Insights.dc.html`: sessions this week and per day, most
  used temperature, average heat-up per device, cleaning card. Footer "Stored
  only on this phone."
- Volcano heating hours: read-only characteristics `10110015` (hours) and
  `10110016` (minutes), listed in `docs/brief.md`, not yet in
  `docs/protocol.md`. **owner**: one read with the debug log, compared with the
  hours the Volcano shows in its menu, before kiln relies on the format.
  Cleaning reminder: interval 10 h by default, "Done" stores the current hours
  as the new baseline.

## 8. Sharing setups

- Payload: model, base, boost, superboost (Volcano: target or a workflow), a
  setup name and an optional sender name, versioned and compact.
- Share sheet per `Share.dc.html`: QR code and "Copy link" / "Share…".
  Receive screen per `Receive.dc.html`: old → new values, "Apply", "Save for
  later". Values are clamped on apply like any other write.
- **owner**: the link needs a home. An `https://` link on a domain you control
  (with `/.well-known/assetlinks.json`) opens kiln directly from any messenger
  and any camera app; a `kiln://` link is not clickable in most messengers.
  New dependency proposed: `qr_flutter` (BSD) for drawing the QR code.

## 9. Connect when the device switches on

- Android `CompanionDeviceManager`: associate a known device once (system
  dialog), then `startObservingDevicePresence`; a presence event starts the
  service and connects. Own Kotlin, after step 5.
- **owner**: hardware check whether a switched-off Venty/Veazy keeps
  advertising (protocol.md: Bluetooth stays up after switching off). If it
  does, presence cannot tell "switched on" from "in range", and kiln would
  only connect, never heat.

## Credits

venty-android (MIT) has ramp profiles, sessions, widgets and a demo mode. Ideas
borrowed from it are credited in the README; no code is copied.
