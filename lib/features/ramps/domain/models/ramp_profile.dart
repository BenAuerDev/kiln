/// Ramps that ship with kiln. Their names come from the `.arb` files.
enum RampPreset { gentle, classic, quick }

/// The base temperature rises from [startCelsius] by [stepCelsius] every
/// [interval] until it reaches [endCelsius].
class RampProfile {
  const RampProfile({
    required this.preset,
    required this.startCelsius,
    required this.stepCelsius,
    required this.interval,
    required this.endCelsius,
  });

  final RampPreset preset;
  final int startCelsius;
  final int stepCelsius;
  final Duration interval;
  final int endCelsius;
}
