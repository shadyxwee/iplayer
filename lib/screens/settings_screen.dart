import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/config_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _videoQuality = 'auto';
  bool _autoPlay = true;
  double _volume = 0.8;
  bool _showAdultContent = false;
  String _videoFit = 'contain';
  final TextEditingController _tmdbController = TextEditingController();
  final TextEditingController _omdbController = TextEditingController();
  bool _isSaving = false;

  bool _obscureTmdb = true;
  bool _obscureOmdb = true;

  @override
  void initState() {
    super.initState();
    _tmdbController.text = ConfigService.getTmdbApiKey();
    _omdbController.text = ConfigService.getOmdbApiKey();
  }

  @override
  void dispose() {
    _tmdbController.dispose();
    _omdbController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKeys() async {
    setState(() => _isSaving = true);
    await ConfigService.updateTmdbKey(_tmdbController.text.trim());
    await ConfigService.updateOmdbKey(_omdbController.text.trim());
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Configuration saved successfully')),
      );
    }
  }

  void _resetApiKeys() {
    setState(() {
      _tmdbController.text = ''; // This will trigger fallback to config.json
      _omdbController.text = '';
    });
    _saveApiKeys();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      appBar: AppBar(
        title: Text(l10n.settings, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: -1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textPrimary,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('API & Metadata', theme),
            _buildMetadataCard(theme, l10n),
            const SizedBox(height: 32),

            _buildSectionHeader(l10n.theme, theme),
            _buildThemeGrid(theme, themeProvider),
            const SizedBox(height: 32),
            
            _buildSectionHeader(l10n.videoSettings, theme),
            _buildSettingsCard(theme, [
              _buildDropdownTile(
                icon: Icons.high_quality_rounded,
                title: l10n.videoQuality,
                value: _videoQuality.toUpperCase(),
                onTap: () => _selectQuality(l10n, theme),
                theme: theme,
              ),
              _buildDropdownTile(
                icon: Icons.aspect_ratio_rounded,
                title: l10n.videoFit,
                value: _videoFit.toUpperCase(),
                onTap: () => _selectVideoFit(l10n, theme),
                theme: theme,
              ),
              _buildSwitchTile(
                icon: Icons.play_arrow_rounded,
                title: l10n.autoPlayOnSelect,
                value: _autoPlay,
                onChanged: (v) => setState(() => _autoPlay = v),
                theme: theme,
              ),
              _buildSliderTile(
                icon: Icons.volume_up_rounded,
                title: l10n.defaultVolume,
                value: _volume,
                onChanged: (v) => setState(() => _volume = v),
                theme: theme,
              ),
            ]),
            const SizedBox(height: 32),

            _buildSectionHeader(l10n.parentalControls, theme),
            _buildSettingsCard(theme, [
              _buildSwitchTile(
                icon: Icons.block_rounded,
                title: l10n.showAdultContent,
                subtitle: l10n.requiresPin,
                value: _showAdultContent,
                onChanged: (value) {
                  if (value) _showPinDialog(theme);
                  else setState(() => _showAdultContent = false);
                },
                theme: theme,
              ),
            ]),
            const SizedBox(height: 32),

            _buildSectionHeader(l10n.dataManagement, theme),
            _buildSettingsCard(theme, [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                ),
                title: Text(l10n.clearAllData, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                subtitle: Text(l10n.clearDataConfirm, style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                onTap: () => _showClearDataDialog(theme),
              ),
            ]),
            const SizedBox(height: 32),

            _buildSectionHeader(l10n.about, theme),
            _buildSettingsCard(theme, [
              _buildInfoTile(Icons.info_outline_rounded, l10n.version, '1.2.0', theme),
              _buildInfoTile(Icons.code_rounded, 'Framework', 'Flutter SDK', theme),
              _buildInfoTile(Icons.storage_rounded, 'Engine', 'Media Kit + Isar', theme),
            ]),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeType theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.textSecondary.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildThemeGrid(AppThemeType theme, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withOpacity(0.5)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: AppThemeType.values.length,
        itemBuilder: (context, index) {
          final themeOption = AppThemeType.values[index];
          final isSelected = themeProvider.currentTheme == themeOption;
          
          return InkWell(
            onTap: () => themeProvider.setTheme(themeOption),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: themeOption.backgroundPrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.accentPrimary : theme.borderPrimary,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: theme.accentPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: themeOption.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      themeOption.displayName,
                      style: TextStyle(
                        color: themeOption.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetadataCard(AppThemeType theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.accentPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: theme.accentPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'API Optimization',
                style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetApiKeys,
                style: TextButton.styleFrom(
                  backgroundColor: theme.accentPrimary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Reset', style: TextStyle(color: theme.accentPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Enhance metadata processing for M3U playlists with external API integration.',
            style: TextStyle(color: theme.textSecondary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          _buildApiKeyField(
            controller: _tmdbController,
            label: 'TMDB API KEY',
            hint: 'Required for high-quality movie posters',
            theme: theme,
            obscureText: _obscureTmdb,
            onToggleVisibility: () => setState(() => _obscureTmdb = !_obscureTmdb),
          ),
          const SizedBox(height: 20),
          _buildApiKeyField(
            controller: _omdbController,
            label: 'OMDB API KEY',
            hint: 'Enhanced metadata for series and lists',
            theme: theme,
            obscureText: _obscureOmdb,
            onToggleVisibility: () => setState(() => _obscureOmdb = !_obscureOmdb),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveApiKeys,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentPrimary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.save_rounded),
              label: const Text('Save API Credentials', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppThemeType theme,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.3)),
            filled: true,
            fillColor: theme.backgroundTertiary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.borderPrimary.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.accentPrimary.withOpacity(0.5))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: theme.textSecondary,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(AppThemeType theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdownTile({required IconData icon, required String title, required String value, required VoidCallback onTap, required AppThemeType theme}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.textSecondary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.accentPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: theme.accentPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more_rounded, color: theme.accentPrimary, size: 14),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged, required AppThemeType theme}) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.textSecondary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 13)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: theme.accentPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildSliderTile({required IconData icon, required String title, required double value, required ValueChanged<double> onChanged, required AppThemeType theme}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.textSecondary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      subtitle: Slider(
        value: value,
        onChanged: onChanged,
        activeColor: theme.accentPrimary,
        inactiveColor: theme.borderPrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, AppThemeType theme) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.textSecondary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      trailing: Text(value, style: TextStyle(color: theme.accentPrimary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w900)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  // --- Dialogs ---

  void _selectQuality(AppLocalizations l10n, AppThemeType theme) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: theme.backgroundSecondary,
        title: Text(l10n.selectQuality, style: TextStyle(color: theme.textPrimary)),
        children: ['auto', '1080p', '720p', '480p'].map((q) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, q),
          child: Text(q.toUpperCase(), style: TextStyle(color: theme.textPrimary)),
        )).toList(),
      ),
    );
    if (result != null) setState(() => _videoQuality = result);
  }

  void _selectVideoFit(AppLocalizations l10n, AppThemeType theme) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: theme.backgroundSecondary,
        title: Text(l10n.selectVideoFit, style: TextStyle(color: theme.textPrimary)),
        children: ['contain', 'cover', 'fitWidth', 'fitHeight'].map((f) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, f),
          child: Text(f.toUpperCase(), style: TextStyle(color: theme.textPrimary)),
        )).toList(),
      ),
    );
    if (result != null) setState(() => _videoFit = result);
  }

  Future<void> _showPinDialog(AppThemeType theme) async {
     final l10n = AppLocalizations.of(context);
     final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(l10n.enterPin, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: TextStyle(color: theme.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.enter4DigitPin, 
              hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.borderPrimary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentPrimary)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentPrimary, foregroundColor: Colors.black),
              child: Text(l10n.ok, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    if (pin == '1234') setState(() => _showAdultContent = true);
  }

  Future<void> _showClearDataDialog(AppThemeType theme) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.clearAllData, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900)),
        content: Text(l10n.clearDataConfirm, style: TextStyle(color: theme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.deleteAllConfirmation, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.allDataCleared)));
        Navigator.pop(context);
      }
    }
  }
}
