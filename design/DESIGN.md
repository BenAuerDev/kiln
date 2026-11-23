# kiln design reference

These files are the approved mockups, written as HTML for a design canvas. Treat them as the visual spec: match layout, spacing, sizes, copy, colours (through theme tokens) and motion. Rebuild them with Obers UI widgets; do not port the HTML. Each screen is 390×844 unless noted.

| File | Screen | Notes |
|---|---|---|
| `Main.dc.html` | Volcano control, dark | 270° gauge with gradient arc and target dot, heat wisps while heating, slow "breathing" pulse when ready. −/+ target, presets, Heater and Air buttons. Props `theme`, `device` (`volcano`/`veazy`), `finish` show every theme variant. |
| `Light.dc.html` | Volcano control, light | Same component in light theme. |
| `VeazyBlue/Pink/Black.dc.html`, `VolcanoOnyx.dc.html` | Theme variants | Main screen per finish. On portables, Boost (+15°) replaces Air and battery shows in the header. |
| `Veazy.dc.html` | Veazy / Venty home | **Priority screen.** "Set it once, then use the button": scale bar with three markers, Base / Boost / Superboost rows with −/+, quick setups (Flavour, Balanced, Full) as a segmented control, "Saved to Veazy" toast after each change. |
| `Finish.dc.html` | Veazy settings (1240 tall, scrolls) | Find my Veazy, Battery (charge limit, battery saver), Device (vibrate when ready, boost on LEDs, °C/°F), App theme per device ("Match my device" + Ember/Lava/Blue/Pink/Mono), Run device check, Forget this device. |
| `Devices.dc.html` | Device list | Known devices with original line-art glyphs (no product imagery), nearby scan. |
| `Workflow.dc.html` | Volcano workflow, light | Step timeline with active step and progress. Later feature. |
| `Insights.dc.html` | Insights | Sessions per week, most-used temperature, cleaning reminder based on **heating hours**, average heat-up. Later feature. |
| `Welcome.dc.html` | First launch | Bluetooth explainer before the system prompt, EN/DE switch, radar scan, found-device card. |
| `Share.dc.html`, `Receive.dc.html` | Share a setup | QR / link sheet; friend sees old → new temperatures and applies them. Later feature. |
| `Widgets.dc.html`, `Live.dc.html` | Outside the app | Home widgets, Live Activity, Android notification, update banner. Later feature. |
| `Icons.dc.html` | App icon | Chosen direction: **A · Gauge**. Final assets are in `assets/icons/`. |

Decided against: an odometer-style rolling temperature. Show the number plainly with tabular figures.

Motion: honour the system "reduce motion" setting by disabling wisps, pulse and spring animations.
