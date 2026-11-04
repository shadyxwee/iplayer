import 'package:flutter/material.dart';

class TVTheme {
  static const Color appDark = Color(0xFF0A0A0C);
  static const Color background = Color(0xFF0B0B0E);
  static const Color panelDark = Color(0xFF121215);
  static const Color cardDark = Color(0xFF17171C);
  static const Color cardHover = Color(0xFF212127);
  static const Color borderDark = Color(0xFF26262E);
  static const Color brandRed = Color(0xFFE50914);
  static const Color accentRed = Color(0xFFFF0033);
  static const Color subtext = Color(0xFF858592);
  static const Color activePill = Color(0xFFEEEEEE);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: brandRed,
      colorScheme: const ColorScheme.dark(
        primary: brandRed,
        secondary: accentRed,
        surface: cardDark,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    );
  }
}
