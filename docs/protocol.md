# Bluetooth protocol

What kiln sends and reads, where each fact comes from, and what was confirmed
on real hardware.

**Sources**

- The official Storz & Bickel web app, v3.4.1 (`app.storz-bickel.com`). Its
  JavaScript was read to see what the official app sends. References like
  `qvap.js:90` point to its files and lines; no code from it is copied here.
- Cross-checked with these open-source projects:
  [storzandbickel-ble](https://github.com/lorek123/snb-ble),
  [reactive-volcano-app](https://github.com/firsttris/reactive-volcano-app),
  [venty-android](https://github.com/orth4x0r/venty-android),
  [Volcano-Remote](https://github.com/xythobuz/Volcano-Remote) and
  [storz-rs](https://github.com/flakesonnix/storz-rs).
- Hardware tests on 2026-11-23 with an Android phone: Veazy (firmware V01.03),
  Venty (V01.11) and Volcano Hybrid. Marked **tested** below.

Every UUID ends in `-5354-4f52-5a26-4249434b454c` unless stated otherwise.

## Device detection

| Device | Advertised name | Service |
|---|---|---|
| Volcano Hybrid | `S&B VOLCANO H` | `10100000`, `10110000` |
| Venty | `S&B VY…` | `00000000` |
| Veazy | `S&B VZ…` | `00000000` |
| Crafty+ | `STORZ&BICKEL` | `0000000{1,2,3}-4c45-4b43-4942-265a524f5453` (not supported yet) |

Source: `main.js`, `whichDeviceConnected()` and the `requestDevice` filters.

## Venty / Veazy

One characteristic, `00000001`, for writes and notifications. Every `0x01`
write is 20 bytes, all zero except the bytes listed. Byte 1 is a write mask: a
packet only sets the mask bits of the bytes it actually fills, so it can never
overwrite another field with zero.

### Init

1. Enable notifications on `00000001`.
2. `02 00…`: firmware info. If reply byte 1 bit `0x01` is clear, the device is
   in bootloader mode and kiln stops without sending anything else.
3. `01 00…`: first status request.
4. `06 00 00 00 00 00 00`: read vibration and brightness.
5. Poll `01 00…` every 500 ms. kiln pauses the poll while the app is in the
   background.

The official app also sends `1D`, `04`, `23`, `05` and `30 06` (`qvap.js:46–53`).
kiln skips them. **Tested:** writes work without them.

### Status packet (reply to `01 00`)

Decoded only when at least 15 bytes long (`qvap.js:63–68`).

| Byte | Meaning |
|---|---|
| 2–3 | Current temperature × 10, uint16 LE. **Tested:** always `0x8000` ("no reading") on Veazy and Venty, also while heating. The official app hides it too. |
| 4–5 | Target × 10, uint16 LE. **Tested:** holds the *boosted* setpoint while heater mode is 2 or 3, so kiln reads the base only in modes 0 and 1. |
| 6 | Boost offset |
| 7 | Superboost offset |
| 8 | Battery % |
| 9, 10 | Auto-off countdown. The official app adds both bytes. **Tested:** byte 9 counts down, byte 10 stayed `00`. |
| 11 | Heater mode: 0 off, 1 normal, 2 boost, 3 superboost |
| 13 | Charger connected |
| 14 | Settings: `0x01` °F, `0x02` setpoint reached, `0x08` eco charge, `0x20` eco voltage, `0x40` boost visualisation (inverted on Veazy) |
| 16 | `0x01` Bluetooth permanent (only if ≥ 17 bytes) |

Settings bit `0x10` is used by the official app as "changed on the device".
**Tested:** a Veazy sets it in every packet, so kiln ignores it.

### Writes

| Write | Packet | Source |
|---|---|---|
| Target | `01 02 00 00 LL HH` (°C × 10, LE) | `qvap.js:97–98` |
| Boost offset | `01 04`, byte 6 = offset | `qvap.js:99` |
| Superboost offset | `01 08`, byte 7 = offset | `qvap.js:101` |
| Heater off / normal | `01 20`, byte 11 = `00` / `01` | `qvap.js:90` |
| Boost | `01 20`, byte 11 = `02` | not in the official app, **tested** |
| Setting | `01 80`, byte 14 = new value, byte 15 = bit to change | `qvap.js:31, 34, 36, 95` |
| Vibration | `06 08 00 00 00 01/00 00` (7 bytes) | `qvap.js:29` |
| Find my device | `0D 01` | `qvap.js:37` |
| Identity (colour) | `05 00…`, reply byte 18: 2 blue, 3 pink, 4 orange, else black | `qvap.js:85` |

kiln limits: target 40–210 °C, offsets 1–30 °C (the official app allows up to 99).

### Boost

**Tested on Veazy and Venty:**

- Heater mode 2 starts boost: the device heats to base + boost and sets the
  "reached" flag.
- Heater mode 1 does **not** end a running boost. Heater off does. kiln ends
  boost with off, then on at the base temperature.
- Target writes are blocked while boosting, because it is unknown whether they
  would set the base or the boosted value.
- Superboost (mode 3) is not sent. kiln has no button for it.

### Connection behaviour

**Tested:** switching a Venty or Veazy off only stops the heater; Bluetooth
stays connected. A switched-off Venty later drops the link and, when
reconnected, vibrates and drops it again 15–30 s later. kiln therefore only
restores a dropped Venty/Veazy connection while the heater is on, and stops
auto-reconnecting after two connections in a row that lasted under 60 s.

## Volcano Hybrid

| Characteristic | Use | Format |
|---|---|---|
| `10110001` | Current temperature (notify) | uint16 LE, °C × 10, first 2 bytes (`volcano.js:75`) |
| `10110003` | Target (read, notify, write) | read uint16 LE; **write uint32 LE**, °C × 10 (`volcano.js:77`, `main.js:68`) |
| `1011000f` / `10110010` | Heater on / off | write one byte `00` (`volcano.js:72`) |
| `10110013` / `10110014` | Pump on / off | write one byte `00` (`volcano.js:74`) |
| `1010000c` | Register 1 (notify) | heater `0x0020`, auto-shutdown `0x0200`, pump `0x2000` |
| `1010000d` | Register 2 | °F `0x0200`, display on cooling `0x1000` (set = off) |
| `1010000e` | Register 3 | vibration `0x0400` (set = off) |

kiln limits the target to 40–230 °C. **Tested:** live temperature, target,
presets, heater and air all work. While heating, the current temperature
arrives in steps of about 4 °C; kiln counts through the degrees in between.

## What kiln never sends

No firmware update, bootloader, factory reset or device analysis command is
defined anywhere in the code. On the Venty/Veazy that rules out command `0x30`,
`0x0C`, the factory-reset settings bit `0x04`, the analysis commands `0x00`,
`0x03` and `0x23`, and any `0x01` packet while the device is in bootloader mode.
On the Volcano it rules out the `…-1989-…` bootloader services and the
`10100011` code-number characteristic.

## Still open

1. Superboost over BLE (heater mode 3).
2. What a Venty sends in identity byte 18 (kiln does not ask a Venty).
3. Whether the 500 ms poll keeps a device from sleeping while kiln is open.
4. The full length of the Volcano temperature characteristics (kiln reads the
   first 2 bytes).
