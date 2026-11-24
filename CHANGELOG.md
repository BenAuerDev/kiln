# Changelog

What changed in each kiln release. The section of a version is also the text
of its GitHub release (`.github/workflows/release.yml`), so write it for the
people installing the APK. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-11-24

### Added

- Home-screen widgets (Android). Add them from your home screen
  (long-press → Widgets → kiln). They start as one row; make them two rows
  tall for the full card.
  - Venty / Veazy: battery, heating status and your base / boost /
    superboost temperatures, with Heat and Boost buttons. Boost steps
    through boost, superboost and off, like the button in the app.
  - Volcano: live temperature with Heat and Air buttons.
  - The buttons work while kiln is running and connected, also in the
    background. Otherwise the widget shows the last values, and a tap opens
    kiln. Demo devices never show up on a widget.

Install the APK over your current version; your devices and settings stay.

## [0.1.0] - 2026-11-23

The first release.

### Added

- Venty and Veazy: live status (target temperature, heating / ready,
  battery, charging), the "set it once" base / boost / superboost setup with
  quick setups, heater, boost and superboost from the phone, device settings
  and find my device.
- Ramps for Venty and Veazy: the base rises step by step during a session.
- Volcano Hybrid: live temperature on a gauge, target with − / + and
  presets, heater and air.
- Volcano workflows: heat, hold and air step by step, with presets and your
  own.
- Background connection while a heater is on (Android), with a notification
  and a "ready" alert.
- Demo mode with a simulated Volcano Hybrid, Venty or Veazy.
- Reconnects to your last device, app colours follow your device's finish,
  English and German, light and dark mode.

[Unreleased]: https://github.com/BenAuerDev/kiln/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/BenAuerDev/kiln/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/BenAuerDev/kiln/releases/tag/v0.1.0
