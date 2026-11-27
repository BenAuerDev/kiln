/// Stored form of a user ramp; the interval in seconds.
class RampDto {
  const RampDto({
    required this.id,
    required this.name,
    required this.startCelsius,
    required this.endCelsius,
    required this.stepCelsius,
    required this.intervalSeconds,
  });

  /// Throws on a malformed entry; the caller skips it.
  factory RampDto.fromJson(Map<String, dynamic> json) => RampDto(
    id: json['id'] as String,
    name: json['name'] as String,
    startCelsius: json['start'] as int,
    endCelsius: json['end'] as int,
    stepCelsius: json['step'] as int,
    intervalSeconds: json['interval'] as int,
  );

  final String id;
  final String name;
  final int startCelsius;
  final int endCelsius;
  final int stepCelsius;
  final int intervalSeconds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': startCelsius,
    'end': endCelsius,
    'step': stepCelsius,
    'interval': intervalSeconds,
  };
}
