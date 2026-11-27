import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ramp_dto.dart';

/// The user's ramps as one JSON list in shared preferences.
class RampsDataSource {
  RampsDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'ramps.v1';

  /// Entries that cannot be read are skipped, not fatal.
  Future<List<RampDto>> readAll() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    final result = <RampDto>[];
    for (final entry in list) {
      try {
        result.add(RampDto.fromJson(entry as Map<String, dynamic>));
      } on Object {
        continue;
      }
    }
    return result;
  }

  Future<void> writeAll(List<RampDto> ramps) => _prefs.setString(
    _key,
    jsonEncode([for (final ramp in ramps) ramp.toJson()]),
  );
}
