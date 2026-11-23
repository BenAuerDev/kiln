/// Every kind of write kiln can send to a Venty/Veazy.
enum PortableWrite {
  statusPoll,
  firmwareInfoRead,
  identityRead,
  settingsRead,
  targetTemperature,
  boostOffset,
  superBoostOffset,
  heaterOn,
  heaterOff,

  /// Not sent by the official app; verified on a Veazy and a Venty.
  heaterBoost,

  /// Not sent by the official app; verified on a Veazy and a Venty.
  heaterSuperBoost,
  setting,
  vibration,
  findDevice,
}

/// Allow-list of writes whose byte layout matches the official web app or
/// was verified on hardware (boost, superboost).
abstract final class PortableWriteSafety {
  static const allowed = {
    PortableWrite.statusPoll,
    PortableWrite.firmwareInfoRead,
    PortableWrite.identityRead,
    PortableWrite.settingsRead,
    PortableWrite.targetTemperature,
    PortableWrite.boostOffset,
    PortableWrite.superBoostOffset,
    PortableWrite.heaterOn,
    PortableWrite.heaterOff,
    PortableWrite.heaterBoost,
    PortableWrite.heaterSuperBoost,
    PortableWrite.setting,
    PortableWrite.vibration,
    PortableWrite.findDevice,
  };

  /// [boostActive]: the heater currently runs in boost or superboost. A
  /// target write is then disabled: it is unverified whether a target
  /// written during boost sets the base or the boosted setpoint.
  static bool isAllowed(PortableWrite write, {required bool boostActive}) {
    if (!allowed.contains(write)) return false;
    if (write == PortableWrite.targetTemperature && boostActive) return false;
    return true;
  }
}
