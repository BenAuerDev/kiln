/// Ramps that ship with kiln. Their names come from the `.arb` files.
enum RampPreset { gentle, classic, quick }

/// The base temperature rises from [startCelsius] by [stepCelsius] every
/// [interval] until it reaches [endCelsius]. Presets have a [preset] and an
/// empty [name]; the user's own ramps have a name and no preset.
class RampProfile {
  const RampProfile({
    required this.id,
    required this.startCelsius,
    required this.stepCelsius,
    required this.interval,
    required this.endCelsius,
    this.name = '',
    this.preset,
  });

  final String id;
  final String name;
  final RampPreset? preset;
  final int startCelsius;
  final int stepCelsius;
  final Duration interval;
  final int endCelsius;

  bool get isPreset => preset != null;

  RampProfile copyWith({
    String? id,
    String? name,
    int? startCelsius,
    int? stepCelsius,
    Duration? interval,
    int? endCelsius,
  }) => RampProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    preset: preset,
    startCelsius: startCelsius ?? this.startCelsius,
    stepCelsius: stepCelsius ?? this.stepCelsius,
    interval: interval ?? this.interval,
    endCelsius: endCelsius ?? this.endCelsius,
  );

  @override
  bool operator ==(Object other) =>
      other is RampProfile &&
      other.id == id &&
      other.name == name &&
      other.preset == preset &&
      other.startCelsius == startCelsius &&
      other.stepCelsius == stepCelsius &&
      other.interval == interval &&
      other.endCelsius == endCelsius;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    preset,
    startCelsius,
    stepCelsius,
    interval,
    endCelsius,
  );
}
