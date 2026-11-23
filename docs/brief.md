# Brief: kiln app skeleton

**kiln** is a Flutter app: an unofficial, polished controller for Storz & Bickel vaporizers (Volcano Hybrid, Venty, Veazy; Crafty+ later) over Bluetooth Low Energy. It replaces the official web app. Distribution is to friends via TestFlight internal testing and Play internal testing, not the public stores.

## Ground rules

- Follow `ARCHITECTURE.md` in the repo root strictly. Put the architecture guide there verbatim, then add the **Addendum** section below to it.
- Effective Dart. No comments that narrate code. Only comment what is genuinely non-obvious, such as a protocol quirk or byte layout.
- `dart analyze` must be clean and `dart format` applied before you finish.
- Never write to firmware, bootloader or factory-reset commands or characteristics. Do not even define constants for them.
- Clamp every temperature write: Volcano 40–230 °C, Venty/Veazy 40–210 °C.
- Do not use any Storz & Bickel logos, product photos or wordmarks. Device names as plain text are fine. Show "Unofficial app, not affiliated with Storz & Bickel" in the about/first-launch screen.

## Project setup

- `flutter create --org dev.bespokecode --project-name kiln --platforms ios,android .` → bundle/application ID `dev.bespokecode.kiln`.
- Dependencies: `signals_flutter`, `get_it` (global `sl`), `flutter_hooks`, `go_router`, `fpdart`, `flutter_blue_plus`, `shared_preferences`, `flutter_localizations` + `intl`.
- UI kit: **Obers UI**, not on pub.dev. Add it as a git dependency:
  ```yaml
  obers_ui:
    git:
      url: https://github.com/SimonErich/obers_ui.git
  ```
  It needs Dart ≥ 3.11 and Flutter ≥ 3.41. Read its `AI_README.md` before building UI and use its components (`OiApp`, buttons, switches, sheets, segmented control, bottom bar, etc.) instead of raw Material widgets.
- Dev dependencies: `mocktail`, `flutter_test`.
- Bluetooth permissions: Android 12+ `BLUETOOTH_SCAN` (with `neverForLocation`) and `BLUETOOTH_CONNECT`; iOS `NSBluetoothAlwaysUsageDescription` ("kiln uses Bluetooth to talk to your vaporizer.").
- l10n: English and German `.arb` files from the start.

## Addendum to ARCHITECTURE.md

1. **Long-running jobs** (workflow runs, auto-reconnect) live in a repository that holds their state in signals, such as `WorkflowRunRepository` or `ConnectionRepository`. Use cases drive them.
2. **View model disposal:** screens are `HookWidget`s that create their view model with `useMemoized(() => sl<XViewModel>())` and dispose it in `useEffect`. View models implement `dispose()` and clean up effects and subscriptions.
3. **Device colours:** the per-device accent palette lives only in the theme file. Extensions such as `DeviceFinishX` return theme tokens, never hex values.
4. **Use cases** may write to the device through repositories. "No side effects" means no UI side effects. Haptics, toasts and navigation live in view models through injected core services (`HapticsService`, `ToastService`, l10n service), so they can be mocked in tests.

## Design

The approved mockups are in `design/` with an index in `design/DESIGN.md`. Read it before building any screen, and match the screens closely using Obers UI. App icons are in `assets/icons/`; wire them up with the `flutter_launcher_icons` config in `assets/icons/README.md`.

## Theme (core/theme)

- Base: `OiThemeData.fromBrand(color: accent, brightness: …)` with light and dark variants, rebuilt when the active device's theme changes.
- Finishes and accents:

  | Finish | Accent | Gradient start → end |
  |---|---|---|
  | ember (default, Volcano silver, Veazy orange) | `#FF7A1A` | `#FFC285` → `#FF6A00` |
  | lava (Volcano Onyx) | `#FF4D2E` | `#FFB199` → `#E5361B` |
  | blue (Veazy Dynamic Blue) | `#3D8BFF` | `#9CC4FF` → `#2F6BFF` |
  | pink (Veazy Charming Pink) | `#FF5FA2` | `#FFB3D3` → `#FF3D8B` |
  | mono (Veazy Alluring Black) | dark `#F9FAFB` / light `#121212` | `#4B5563` → `#FFFFFF` |

- Small accent-coloured text on light backgrounds uses darker variants: ember `#C2410C`, lava `#B42318`, blue `#1D4ED8`, pink `#BE185D`.
- Fonts: Space Grotesk for numbers and headings (tabular figures), Inter for body text.
- Each known device stores its chosen finish. The default is "match my device", falling back to ember while detection is unknown.

## Features for this first pass

### `devices`
- Scan for S&B devices, connect, remember known devices (`shared_preferences`), forget a device, and store a theme per device.
- Domain: `DeviceModel` enum (`volcanoHybrid`, `venty`, `veazy`, `craftyPlus`), `DeviceFinish` enum, `KnownDevice`, `ConnectionStatus`.
- Auto-reconnect to the last device when the app starts or resumes.

### `portable` (Venty and Veazy share one protocol)
- Live status: current temperature, target, boost and superboost offsets, battery, charging, heater mode.
- Edit base temperature, boost offset and superboost offset. This is the "set it once, then use the button" screen from the design.
- View model haptics: a light tick per degree step, plus a success haptic and a "Saved to Veazy" toast after each write.

### `volcano`
- Data source and DTOs with the UUIDs below, plus a minimal screen showing current and target temperature with heater and air toggles. A workflow comes later.

## Protocol reference (from the open-source `storzandbickel-ble` library; verify before writing)

> Superseded by [`protocol.md`](protocol.md): several notes below turned out to be wrong.

**Volcano Hybrid**: service `10110000-5354-4f52-5a26-4249434b454c`; info service `10100000-…`
- Current temperature `10110001-…` (notify), target temperature `10110003-…`: °C × 10, little-endian. That library uses 2 bytes, while other projects write 4 (uint32). Check what the official web app writes.
- Heater on `1011000f-…`, heater off `10110010-…`, pump on `10110013-…`, pump off `10110014-…`
- LED brightness `10110005-…` (1–9), auto-off `1011000c-…`, heating hours `10110015-…`, heating minutes `10110016-…`
- Firmware `10100005-…`, BLE firmware `10100004-…`, serial `10100008-…`, status registers 1/2/3 `1010000c/d/e-…`
- Status register 1 bits: heater `0x0020`, auto-shutdown `0x0200`, pump `0x2000`. Register 2: Fahrenheit `0x0200`, display on cooling `0x1000`. Register 3: vibration when ready `0x0400`.

(Every `…` suffix is `-5354-4f52-5a26-4249434b454c`.)

**Venty / Veazy**: one characteristic `00000001-5354-4f52-5a26-4249434b454c` (write and notify), 20-byte packets.
- Byte 0 = command: `0x01` status/control, `0x02` firmware, `0x03` device analysis, `0x04` usage stats (reply format undocumented), `0x05` serial, `0x06` settings, `0x13` find device.
- Status packet (`0x01`): bytes 2–3 current temperature ×10 (little-endian), 4–5 target ×10, 6 boost offset, 7 superboost offset, 8 battery %, 9–10 auto-off countdown in seconds, 11 heater mode (0 off, 1 normal, 2 boost, 3 superboost), 13 charger connected, 14 settings bits.
- Settings bits (byte 14): `0x01` Fahrenheit, `0x02` vibrate when ready, `0x08` eco charge (charge limit), `0x20` eco voltage (battery saver), `0x40` boost visualisation on LEDs.
- Write mask (byte 1) selects which fields apply: `0x02` target temperature, `0x04` boost, `0x08` superboost, `0x20` heater, `0x80` settings.

⚠️ **Verify writes before sending them.** In that library, the "start periodic updates" packet uses mask `0x06` with zeroed fields, and its boost heater-mode command sets the boost mask with offset byte 0. Both look like they could overwrite the target temperature or boost offset. Build and test the decoders first (read-only). Then confirm each write packet against the official web app (`app.storz-bickel.com`, unminified JS) or an Android HCI snoop capture before enabling it.

## Tests

- Unit tests for every use case (happy path and edge cases, including clamping).
- Codec tests: decoding real-looking Venty status packets and Volcano temperatures, and encoding each write packet byte-for-byte.
- Repository tests with mocked data sources, including the error path to `Either`.

## Done when

- The app builds for Android and iOS, `dart analyze` is clean, and all tests pass.
- On a real phone it scans, connects to a Veazy or Venty, shows live temperature and battery, and edits base, boost and superboost with haptics, in that device's theme, in English and German.
- `README.md` explains how to run it and lists the protocol facts that still need verifying.
