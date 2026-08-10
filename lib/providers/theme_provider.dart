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

  // Deep dark purple-black backgrounds across all pages
  Color get backgroundPrimary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF06030C);
      case AppThemeType.nordic:
        return const Color(0xFF06040F);
      case AppThemeType.obsidian:
        return const Color(0xFF05030B);
      case AppThemeType.emerald:
        return const Color(0xFF04030D);
      case AppThemeType.royal:
        return const Color(0xFF070412);
      case AppThemeType.sunset:
        return const Color(0xFF06030E);
    }
  }

  Color get backgroundSecondary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF0B0616);
      case AppThemeType.nordic:
        return const Color(0xFF0B081B);
      case AppThemeType.obsidian:
        return const Color(0xFF0C071A);
      case AppThemeType.emerald:
        return const Color(0xFF09081B);
      case AppThemeType.royal:
        return const Color(0xFF0E0824);
      case AppThemeType.sunset:
        return const Color(0xFF0C061C);
    }
  }

  Color get backgroundTertiary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF120924);
      case AppThemeType.nordic:
        return const Color(0xFF120E2C);
      case AppThemeType.obsidian:
        return const Color(0xFF150D2D);
      case AppThemeType.emerald:
        return const Color(0xFF100F2F);
      case AppThemeType.royal:
        return const Color(0xFF170E3A);
      case AppThemeType.sunset:
        return const Color(0xFF150A2E);
    }
  }

  Color get sidebarBackground {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF080410);
      case AppThemeType.nordic:
        return const Color(0xFF080512);
      case AppThemeType.obsidian:
        return const Color(0xFF07040E);
      case AppThemeType.emerald:
        return const Color(0xFF060410);
      case AppThemeType.royal:
        return const Color(0xFF090516);
      case AppThemeType.sunset:
        return const Color(0xFF080411);
    }
  }

  Color get cardBackground {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF160D2A);
      case AppThemeType.nordic:
        return const Color(0xFF151030);
      case AppThemeType.obsidian:
        return const Color(0xFF191036);
      case AppThemeType.emerald:
        return const Color(0xFF141337);
      case AppThemeType.royal:
        return const Color(0xFF1C1145);
      case AppThemeType.sunset:
        return const Color(0xFF190C36);
    }
  }

  Color get cardBackgroundLight {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF26194C);
      case AppThemeType.nordic:
        return const Color(0xFF251A52);
      case AppThemeType.obsidian:
        return const Color(0xFF291B58);
      case AppThemeType.emerald:
        return const Color(0xFF241E59);
      case AppThemeType.royal:
        return const Color(0xFF2C1E67);
      case AppThemeType.sunset:
        return const Color(0xFF291B58);
    }
  }

  Color get cardTextPrimary {
    return Colors.white;
  }

  Color get cardTextSecondary {
    return Colors.white.withValues(alpha: 0.6);
  }

  // Soft purple-tinted borders for subtle purple glow aesthetic
  Color get borderPrimary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFF4C1E9E);
      case AppThemeType.nordic:
        return const Color(0xFF2C3E9C);
      case AppThemeType.obsidian:
        return const Color(0xFF6F3E9C);
      case AppThemeType.emerald:
        return const Color(0xFF1E6C9E);
      case AppThemeType.royal:
        return const Color(0xFF7229E6);
      case AppThemeType.sunset:
        return const Color(0xFF8A1E9E);
    }
  }

  // Vibrant purple/neon accents for highlights, active states, and buttons
  Color get accentPrimary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFFB557FF); // Vibrant Violet
      case AppThemeType.nordic:
        return const Color(0xFF8C52FF); // Medium Purple-Indigo
      case AppThemeType.obsidian:
        return const Color(0xFFD631FF); // Intense Pink-Purple
      case AppThemeType.emerald:
        return const Color(0xFF6E00FF); // Deep electric indigo-violet
      case AppThemeType.royal:
        return const Color(0xFFDF40FF); // High-contrast magenta purple
      case AppThemeType.sunset:
        return const Color(0xFFFF40D9); // Hot magenta neon
    }
  }

  Color get accentSecondary {
    switch (this) {
      case AppThemeType.midnight:
        return const Color(0xFFEA48FF);
      case AppThemeType.nordic:
        return const Color(0xFF00E5FF);
      case AppThemeType.obsidian:
        return const Color(0xFFFFD700);
      case AppThemeType.emerald:
        return const Color(0xFF00E676);
      case AppThemeType.royal:
        return const Color(0xFFFFAB40);
      case AppThemeType.sunset:
        return const Color(0xFFFF3D00);
    }
  }

  Color get textPrimary {
    return Colors.white;
  }

  Color get textSecondary {
    return const Color(0xFFB0B0C0); // Soft gray typography
  }

  // Premium gradient support with purple elements
  List<Color> get primaryGradient {
    return [accentPrimary, const Color(0xFF7B1FA2)];
  }

  // Soft rounded glass-style cards decoration with subtle purple glow
  BoxDecoration glassCardDecoration({double borderRadius = 20, bool hasGlow = true}) {
    final glowColor = accentPrimary.withValues(alpha: 0.18);
    return BoxDecoration(
      color: cardBackground.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderPrimary.withValues(alpha: 0.35),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        if (hasGlow)
          BoxShadow(
            color: glowColor,
            blurRadius: 20,
            spreadRadius: -4,
          ),
      ],
    );
  }
}
