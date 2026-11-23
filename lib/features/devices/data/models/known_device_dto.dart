class KnownDeviceDto {
  const KnownDeviceDto({
    required this.id,
    required this.name,
    required this.model,
    required this.finish,
    this.detectedFinish,
    this.lastConnectedAt,
  });

  factory KnownDeviceDto.fromJson(Map<String, Object?> json) => KnownDeviceDto(
    id: json['id']! as String,
    name: json['name']! as String,
    model: json['model']! as String,
    finish: json['finish']! as String,
    detectedFinish: json['detectedFinish'] as String?,
    lastConnectedAt: json['lastConnectedAt'] as String?,
  );

  final String id;
  final String name;

  /// `DeviceModel.name`.
  final String model;

  /// `match` or a `DeviceFinish.name`.
  final String finish;
  final String? detectedFinish;

  /// ISO 8601.
  final String? lastConnectedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'model': model,
    'finish': finish,
    'detectedFinish': ?detectedFinish,
    'lastConnectedAt': ?lastConnectedAt,
  };
}
