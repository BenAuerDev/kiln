import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workflow_dto.dart';

/// The user's workflows as one JSON list in shared preferences.
class WorkflowsDataSource {
  WorkflowsDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'workflows.v1';

  /// Entries that cannot be read are skipped, not fatal.
  Future<List<WorkflowDto>> readAll() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    final result = <WorkflowDto>[];
    for (final entry in list) {
      try {
        result.add(WorkflowDto.fromJson(entry as Map<String, dynamic>));
      } on Object {
        continue;
      }
    }
    return result;
  }

  Future<void> writeAll(List<WorkflowDto> workflows) => _prefs.setString(
    _key,
    jsonEncode([for (final workflow in workflows) workflow.toJson()]),
  );
}
