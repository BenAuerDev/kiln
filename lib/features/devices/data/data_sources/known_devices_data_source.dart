import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/known_device_dto.dart';

class KnownDevicesDataSource {
  KnownDevicesDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _devicesKey = 'devices.known';
  static const _lastDeviceKey = 'devices.last_id';

  Future<List<KnownDeviceDto>> readAll() async {
    final raw = await _prefs.getString(_devicesKey);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(KnownDeviceDto.fromJson)
        .toList();
  }

  Future<void> writeAll(List<KnownDeviceDto> devices) => _prefs.setString(
    _devicesKey,
    jsonEncode(devices.map((d) => d.toJson()).toList()),
  );

  Future<String?> readLastDeviceId() => _prefs.getString(_lastDeviceKey);

  Future<void> writeLastDeviceId(String? id) => id == null
      ? _prefs.remove(_lastDeviceKey)
      : _prefs.setString(_lastDeviceKey, id);
}
