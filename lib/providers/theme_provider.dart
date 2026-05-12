import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage the application theme
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';

  AppThemeType _currentTheme = AppThemeType.midnight;

  AppThemeType get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  /// Load saved theme
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? 'midnight';
    _currentTheme = AppThemeType.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => AppThemeType.midnight,
    );
    notifyListeners();
  }

  /// Change theme
  Future<void> setTheme(AppThemeType theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    notifyListeners();
  }

  /// Toggle between themes
  Future<void> toggleTheme() async {
    final nextIndex = (_currentTheme.index + 1) % AppThemeType.values.length;
    await setTheme(AppThemeType.values[nextIndex]);
  }
}

/// Available theme types
enum AppThemeType {
  midnight,
  nordic,
  obsidian,
  emerald,
  royal,
  sunset,
}

/// Extension to get colors based on the theme
extension AppThemeTypeExtension on AppThemeType {
  String get displayName {
    switch (this) {
      case AppThemeType.midnight:
        return 'Midnight Bloom';
      case AppThemeType.nordic:
        return 'Nordic Slate';
      case AppThemeType.obsidian:
        return 'Obsidian Gold';
      case AppThemeType.emerald:
        return 'Emerald Night';
      case AppThemeType.royal:
        return 'Royal Velvet';
      case AppThemeType.sunset:
        return 'Sunset Peak';
    }
  }

  // Main colors
  Color get backgroundPrimary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF12141B);
      case AppThemeType.nordic:
        return const Color(0xFF1A1C1E);
      case AppThemeType.obsidian:
        return const Color(0xFF0F0F0F);
      case AppThemeType.emerald:
        return const Color(0xFF0A1412);
      case AppThemeType.royal:
        return const Color(0xFF120E1A);
      case AppThemeType.sunset:
        return const Color(0xFF1A0F0F);
    }
  }

  Color get backgroundSecondary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF181B24);
      case AppThemeType.nordic:
        return const Color(0xFF232629);
      case AppThemeType.obsidian:
        return const Color(0xFF1A1A1A);
      case AppThemeType.emerald:
        return const Color(0xFF11211E);
      case AppThemeType.royal:
        return const Color(0xFF1A1426);
      case AppThemeType.sunset:
        return const Color(0xFF241414);
    }
  }

  Color get backgroundTertiary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF1E2129);
      case AppThemeType.nordic:
        return const Color(0xFF2D3033);
      case AppThemeType.obsidian:
        return const Color(0xFF242424);
      case AppThemeType.emerald:
        return const Color(0xFF1A2E2A);
      case AppThemeType.royal:
        return const Color(0xFF241C33);
      case AppThemeType.sunset:
        return const Color(0xFF331C1C);
    }
  }

  Color get sidebarBackground {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF16181F);
      case AppThemeType.nordic:
        return const Color(0xFF1E2022);
      case AppThemeType.obsidian:
        return const Color(0xFF121212);
      case AppThemeType.emerald:
        return const Color(0xFF0E1A17);
      case AppThemeType.royal:
        return const Color(0xFF16121E);
      case AppThemeType.sunset:
        return const Color(0xFF1E1616);
    }
  }

  Color get cardBackground {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF1E2129);
      case AppThemeType.nordic:
        return const Color(0xFF2D3033);
      case AppThemeType.obsidian:
        return const Color(0xFF1F1F1F);
      case AppThemeType.emerald:
        return const Color(0xFF1A2E2A);
      case AppThemeType.royal:
        return const Color(0xFF241C33);
      case AppThemeType.sunset:
        return const Color(0xFF331C1C);
    }
  }

  Color get cardBackgroundLight {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF282C37);
      case AppThemeType.nordic:
        return const Color(0xFF383C40);
      case AppThemeType.obsidian:
        return const Color(0xFF2A2A2A);
      case AppThemeType.emerald:
        return const Color(0xFF233D38);
      case AppThemeType.royal:
        return const Color(0xFF2F2442);
      case AppThemeType.sunset:
        return const Color(0xFF422424);
    }
  }

  Color get cardTextPrimary {
    return Colors.white;
  }

  Color get cardTextSecondary {
    return Colors.white.withOpacity(0.6);
  }

  Color get borderPrimary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF2C313E);
      case AppThemeType.nordic:
        return const Color(0xFF3E4348);
      case AppThemeType.obsidian:
        return const Color(0xFF333333);
      case AppThemeType.emerald:
        return const Color(0xFF2E4842);
      case AppThemeType.royal:
        return const Color(0xFF3A2E50);
      case AppThemeType.sunset:
        return const Color(0xFF502E2E);
    }
  }

  Color get accentPrimary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFFBB86FC); // Soft Purple
      case AppThemeType.nordic:
        return const Color(0xFF81D4FA); // Soft Blue
      case AppThemeType.obsidian:
        return const Color(0xFFFFD700); // Gold
      case AppThemeType.emerald:
        return const Color(0xFF00C853); // Emerald Green
      case AppThemeType.royal:
        return const Color(0xFFE040FB); // Vibrant Purple
      case AppThemeType.sunset:
        return const Color(0xFFFF5252); // Vibrant Red/Coral
    }
  }

  Color get accentSecondary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF03DAC6); // Teal
      case AppThemeType.nordic:
        return const Color(0xFF90CAF9); // Light Blue
      case AppThemeType.obsidian:
        return const Color(0xFFFFA000); // Amber
      case AppThemeType.emerald:
        return const Color(0xFF64FFDA); // Aqua
      case AppThemeType.royal:
        return const Color(0xFFFFAB40); // Vibrant Amber
      case AppThemeType.sunset:
        return const Color(0xFFFF8A80); // Vibrant Pink
    }
  }

  Color get textPrimary {
    return Colors.white;
  }

  Color get textSecondary {
    return Colors.white.withOpacity(0.6);
  }

  // New gradient support for premium feel
  List<Color> get primaryGradient {
    switch (this) {
      case AppThemeType.midnight:
        return [const Color(0xFFBB86FC), const Color(0xFF6200EE)];
      case AppThemeType.nordic:
        return [const Color(0xFF81D4FA), const Color(0xFF0288D1)];
      case AppThemeType.obsidian:
        return [const Color(0xFFFFD700), const Color(0xFFB8860B)];
      case AppThemeType.emerald:
        return [const Color(0xFF00C853), const Color(0xFF1B5E20)];
      case AppThemeType.royal:
        return [const Color(0xFFE040FB), const Color(0xFF7B1FA2)];
      case AppThemeType.sunset:
        return [const Color(0xFFFF5252), const Color(0xFFFF9100)];
    }
  }
}
