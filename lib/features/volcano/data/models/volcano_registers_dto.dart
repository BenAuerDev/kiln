import 'volcano_codec.dart';

/// Register 1 (`1010000c`).
class VolcanoRegister1Dto {
  const VolcanoRegister1Dto({
    required this.heaterOn,
    required this.autoShutdown,
    required this.pumpOn,
  });

  factory VolcanoRegister1Dto.decode(List<int> bytes) {
    final value = VolcanoCodec.decodeRegister(bytes);
    return VolcanoRegister1Dto(
      heaterOn: value & heaterMask != 0,
      autoShutdown: value & autoShutdownMask != 0,
      pumpOn: value & pumpMask != 0,
    );
  }

  static const heaterMask = 0x0020;
  static const autoShutdownMask = 0x0200;
  static const pumpMask = 0x2000;

  final bool heaterOn;
  final bool autoShutdown;
  final bool pumpOn;
}

/// Register 2 (`1010000d`).
class VolcanoRegister2Dto {
  const VolcanoRegister2Dto({
    required this.fahrenheit,
    required this.displayOnCooling,
  });

  factory VolcanoRegister2Dto.decode(List<int> bytes) {
    final value = VolcanoCodec.decodeRegister(bytes);
    return VolcanoRegister2Dto(
      fahrenheit: value & fahrenheitMask != 0,
      // Inverted: the bit set means "display on cooling" is disabled.
      displayOnCooling: value & displayOnCoolingDisabledMask == 0,
    );
  }

  static const fahrenheitMask = 0x0200;
  static const displayOnCoolingDisabledMask = 0x1000;

  final bool fahrenheit;
  final bool displayOnCooling;
}

/// Register 3 (`1010000e`).
class VolcanoRegister3Dto {
  const VolcanoRegister3Dto({required this.vibrationWhenReady});

  factory VolcanoRegister3Dto.decode(List<int> bytes) {
    final value = VolcanoCodec.decodeRegister(bytes);
    // Inverted: the bit set means vibration is disabled.
    return VolcanoRegister3Dto(
      vibrationWhenReady: value & vibrationDisabledMask == 0,
    );
  }

  static const vibrationDisabledMask = 0x0400;

  final bool vibrationWhenReady;
}
