/// GATT UUIDs of the Volcano Hybrid that kiln reads or writes.
///
/// Only characteristics on `VolcanoWriteSafety`'s allow-list are ever written.
/// Nothing else is defined on purpose.
abstract final class VolcanoUuids {
  static const _suffix = '-5354-4f52-5a26-4249434b454c';

  /// Device state service: status registers.
  static const stateService = '10100000$_suffix';

  /// Heater, pump and temperature service.
  static const controlService = '10110000$_suffix';

  /// Register 1: heater, auto shutdown, pump.
  static const register1 = '1010000c$_suffix';

  /// Register 2: Fahrenheit, display on cooling.
  static const register2 = '1010000d$_suffix';

  /// Register 3: vibration when ready.
  static const register3 = '1010000e$_suffix';

  static const currentTemperature = '10110001$_suffix';
  static const targetTemperature = '10110003$_suffix';
  static const heaterOn = '1011000f$_suffix';
  static const heaterOff = '10110010$_suffix';
  static const pumpOn = '10110013$_suffix';
  static const pumpOff = '10110014$_suffix';
}
