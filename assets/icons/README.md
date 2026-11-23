# kiln app icons

Gauge icon in five themes: `ember` (default), `lava`, `blue`, `pink`, `mono`.
Every PNG is 1024×1024 and has an SVG source in `svg/` with the same path.

## iOS

| File | Use |
|---|---|
| `ios/<theme>/app_icon.png` | Main icon, opaque, full bleed (iOS applies the corner mask) |
| `ios/<theme>/app_icon_dark.png` | iOS 18+ dark appearance, transparent background |
| `ios/tinted.png` | iOS 18+ tinted appearance, grayscale |

`ember` is the primary icon. The other themes are alternate icons, switched at runtime with `setAlternateIconName`.

## Android

| File | Use |
|---|---|
| `android/<theme>/foreground.png` | Adaptive icon foreground, glyph inside the 66dp safe zone of the 108dp canvas |
| `android/<theme>/background.png` | Adaptive icon background (`#0A0A0F`) |
| `android/monochrome.png` | Themed icon (Android 13+), tinted by the system |

## flutter_launcher_icons

```yaml
flutter_launcher_icons:
  image_path: "assets/icons/ios/ember/app_icon.png"
  ios: true
  remove_alpha_ios: true
  android: true
  adaptive_icon_background: "#0A0A0F"
  adaptive_icon_foreground: "assets/icons/android/ember/foreground.png"
  adaptive_icon_monochrome: "assets/icons/android/monochrome.png"
```
