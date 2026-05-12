import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../providers/theme_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final theme = context.watch<ThemeProvider>().currentTheme;

    return AlertDialog(
      backgroundColor: theme.backgroundTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Select Language',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: languageService.availableLanguages.map((lang) {
            return _buildLanguageItem(context, theme, languageService, lang['name']!, lang['code']!);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, AppThemeType theme, LanguageService service, String name, String code) {
    final isSelected = service.currentLocale.languageCode == code;

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
        title: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: theme.accentPrimary, size: 20)
            : null,
        onTap: () {
          service.changeLanguage(code);
          Navigator.pop(context);
        },
      ),
    );
  }
}
