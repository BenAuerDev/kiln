/// Stored form of one workflow step: `type` is `heat` (value °C), `hold` or
/// `air` (value seconds).
class WorkflowStepDto {
  const WorkflowStepDto({required this.type, required this.value});

  factory WorkflowStepDto.fromJson(Map<String, dynamic> json) =>
      WorkflowStepDto(
        type: json['type'] as String,
        value: json['value'] as int,
      );

  final String type;
  final int value;

  Map<String, dynamic> toJson() => {'type': type, 'value': value};
}

/// Stored form of a user workflow.
class WorkflowDto {
  const WorkflowDto({
    required this.id,
    required this.name,
    required this.heaterOffAtEnd,
    required this.steps,
  });

  /// Throws on a malformed entry; the caller skips it.
  factory WorkflowDto.fromJson(Map<String, dynamic> json) => WorkflowDto(
    id: json['id'] as String,
    name: json['name'] as String,
    heaterOffAtEnd: json['heaterOffAtEnd'] as bool,
    steps: [
      for (final step in json['steps'] as List<dynamic>)
        WorkflowStepDto.fromJson(step as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final bool heaterOffAtEnd;
  final List<WorkflowStepDto> steps;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'heaterOffAtEnd': heaterOffAtEnd,
    'steps': [for (final step in steps) step.toJson()],
  };
}
