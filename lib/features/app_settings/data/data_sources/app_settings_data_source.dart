import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsDataSource {
  AppSettingsDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _localeKey = 'app_settings.locale';
  static const _welcomeKey = 'app_settings.welcome_completed';

  Future<String?> readLocaleCode() => _prefs.getString(_localeKey);

  Future<void> writeLocaleCode(String? code) => code == null
      ? _prefs.remove(_localeKey)
      : _prefs.setString(_localeKey, code);

  Future<bool> readWelcomeCompleted() async =>
      await _prefs.getBool(_welcomeKey) ?? false;

  Future<void> writeWelcomeCompleted() => _prefs.setBool(_welcomeKey, true);
}
