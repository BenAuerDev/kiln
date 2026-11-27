import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ramp_dto.dart';

/// The user's ramps as one JSON list in shared preferences, and the id of
/// the chosen ramp (a preset or user ramp).
class RampsDataSource {
  RampsDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'ramps.v1';
  static const _selectedKey = 'ramps.selected.v1';

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

  /// `null` until a ramp was chosen.
  Future<String?> readSelected() => _prefs.getString(_selectedKey);

  Future<void> writeSelected(String id) => _prefs.setString(_selectedKey, id);

  Future<void> writeAll(List<RampDto> ramps) => _prefs.setString(
    _key,
    jsonEncode([for (final ramp in ramps) ramp.toJson()]),
  );
}
