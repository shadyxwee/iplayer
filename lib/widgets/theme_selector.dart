import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return AlertDialog(
      backgroundColor: theme.backgroundTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Select Theme',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeType.values.map((t) => _buildThemeItem(context, themeProvider, t)).toList(),
        ),
      ),
    );
  }

  Widget _buildThemeItem(BuildContext context, ThemeProvider provider, AppThemeType theme) {
    final currentTheme = provider.currentTheme;
    final isSelected = currentTheme == theme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.accentPrimary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? theme.accentPrimary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          theme.displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: theme.accentPrimary, size: 20)
            : null,
        onTap: () {
          provider.setTheme(theme);
          Navigator.pop(context);
        },
      ),
    );
  }
}
