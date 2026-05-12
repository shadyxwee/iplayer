import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('en', 'US');

  Locale get currentLocale => _currentLocale;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      _currentLocale = _getLocaleFromCode(languageCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = _getLocaleFromCode(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }

  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'es':
        return const Locale('es', 'ES');
      case 'en':
        return const Locale('en', 'US');
      case 'zh':
        return const Locale('zh', 'CN');
      case 'ru':
        return const Locale('ru', 'RU');
      default:
        return const Locale('en', 'US');
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ru':
        return 'Русский';
      default:
        return 'English';
    }
  }

  List<Map<String, String>> get availableLanguages => [
        {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
        {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
        {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
        {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
      ];
}
