import 'dart:convert';
import 'package:flutter/services.dart';
import 'preferences_service.dart';

class ConfigService {
  static Map<String, dynamic> _defaults = {};
  static String? _userTmdbKey;
  static String? _userOmdbKey;

  static Future<void> initialize() async {
    try {
      final jsonString = await rootBundle.loadString('config.json');
      _defaults = jsonDecode(jsonString);
    } catch (e) {
      // Fallback or ignore if config.json is missing or invalid
    }

    _userTmdbKey = await PreferencesService.getTmdbApiKey();
    _userOmdbKey = await PreferencesService.getOmdbApiKey();
  }

  static bool isTmdbConfigured() {
    final key = getTmdbApiKey();
    return key.isNotEmpty && key != 'YOUR_TMDB_API_KEY_HERE';
  }

  static String getTmdbBaseUrl() => _defaults['apis']?['tmdb']?['baseUrl'] ?? 'https://api.themoviedb.org/3';
  
  static String getTmdbApiKey() {
    if (_userTmdbKey != null && _userTmdbKey!.isNotEmpty) return _userTmdbKey!;
    return _defaults['apis']?['tmdb']?['apiKey'] ?? '';
  }

  static String getOmdbBaseUrl() => _defaults['apis']?['omdb']?['baseUrl'] ?? 'http://www.omdbapi.com';

  static String getOmdbApiKey() {
    if (_userOmdbKey != null && _userOmdbKey!.isNotEmpty) return _userOmdbKey!;
    return _defaults['apis']?['omdb']?['apiKey'] ?? '';
  }

  static Future<void> updateTmdbKey(String key) async {
    await PreferencesService.setTmdbApiKey(key);
    _userTmdbKey = key;
  }

  static Future<void> updateOmdbKey(String key) async {
    await PreferencesService.setOmdbApiKey(key);
    _userOmdbKey = key;
  }
}
