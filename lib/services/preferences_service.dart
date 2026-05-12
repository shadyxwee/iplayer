import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _activePlaylistIdKey = 'active_playlist_id';
  static const String _tmdbApiKey = 'tmdb_api_key';
  static const String _omdbApiKey = 'omdb_api_key';
  static const String _tmdbBaseUrl = 'tmdb_base_url';
  static const String _omdbBaseUrl = 'omdb_base_url';

  static Future<int?> getActivePlaylistId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activePlaylistIdKey);
  }

  static Future<void> setActivePlaylistId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activePlaylistIdKey, id);
  }

  static Future<String?> getTmdbApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tmdbApiKey);
  }

  static Future<void> setTmdbApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tmdbApiKey, apiKey);
  }

  static Future<String?> getOmdbApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_omdbApiKey);
  }

  static Future<void> setOmdbApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_omdbApiKey, apiKey);
  }
}
