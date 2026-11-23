/// Byte values of the Venty/Veazy protocol that kiln uses.
///
/// Source: `docs/protocol.md` (official web app `qvap.js`).
/// Firmware, bootloader, factory-reset and analysis commands are deliberately
/// not defined here.
abstract final class PortableCommand {
  /// Status (`01 00…` request, notification reply) and `0x01` writes.
  static const status = 0x01;

  /// Firmware info request / reply (bootloader flag in byte 1).
  static const firmwareInfo = 0x02;

  /// Identity request / reply (serial; Veazy colour index in byte 18).
  static const identity = 0x05;

  /// Brightness / vibration read and vibration write (7-byte packets).
  static const deviceSettings = 0x06;

  /// Find my device (`0D 01`).
  static const findDevice = 0x0D;
}

/// Byte 1 of a `0x01` write: which fields the device should apply.
abstract final class PortableWriteMask {
  static const targetTemperature = 0x02;
  static const boostOffset = 0x04;
  static const superBoostOffset = 0x08;
  static const heater = 0x20;
  static const settings = 0x80;
}

/// Bits of byte 14 (settings) in a status notification.
///
/// `0x04` (factory reset) is intentionally missing.
abstract final class PortableSettingsBit {
  static const fahrenheit = 0x01;

  /// Read-only: the heater reached its setpoint.
  static const setpointReached = 0x02;
  static const ecoCharge = 0x08;

  /// Read-only: the target was changed with the device buttons.
  static const changedOnDevice = 0x10;
  static const ecoVoltage = 0x20;

  /// Inverted on a Veazy (bit set = visualisation off).
  static const boostVisualisation = 0x40;
}

/// Byte 16 (settings2) in a status notification.
abstract final class PortableSettings2Bit {
  static const blePermanent = 0x01;
}

/// Byte 1 of a `0x06` write.
abstract final class PortableDeviceSettingsMask {
  static const vibration = 0x08;
}

/// Byte 1 of a `0x02` reply.
abstract final class PortableFirmwareFlag {
  static const applicationRunning = 0x01;
}

/// Byte 11 of a status notification / heater write.
abstract final class PortableHeaterModeCode {
  static const off = 0;
  static const normal = 1;
  static const boost = 2;
  static const superBoost = 3;
}

/// The byte-14 settings that kiln may write. A settings write can only be
/// built from one of these, so the factory-reset bit cannot be sent.
enum PortableWritableSetting {
  fahrenheit(PortableSettingsBit.fahrenheit),
  ecoCharge(PortableSettingsBit.ecoCharge),
  ecoVoltage(PortableSettingsBit.ecoVoltage),

  /// Raw bit value. The Veazy inversion is applied by the caller.
  boostVisualisation(PortableSettingsBit.boostVisualisation);

  const PortableWritableSetting(this.bit);

  final int bit;
}
