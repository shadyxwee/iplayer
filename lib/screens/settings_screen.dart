import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/config_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/preferences_service.dart';
import '../utils/responsive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _activeSection = 'playback'; // 'playback', 'appearance', 'api', 'parental', 'database', 'about'
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
      _tmdbController.text = '';
      _omdbController.text = '';
    });
    _saveApiKeys();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final bool isDesktop = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          l10n.settings.toUpperCase(),
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textPrimary,
        centerTitle: false,
      ),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(theme, themeProvider, l10n)
            : _buildMobileLayout(theme, themeProvider, l10n),
      ),
    );
  }

  // ── DESKTOP SPLIT SIDEBAR LAYOUT ─────────────────────────
  Widget _buildDesktopLayout(AppThemeType theme, ThemeProvider themeProvider, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Menu (30% Width)
        Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.04),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildSidebarItem('playback', 'Playback & Video', Icons.play_circle_filled_rounded, theme),
              _buildSidebarItem('appearance', 'Theme & Color', Icons.palette_rounded, theme),
              _buildSidebarItem('api', 'API & Metadata', Icons.auto_awesome_rounded, theme),
              _buildSidebarItem('parental', 'Parental Lock', Icons.lock_rounded, theme),
              _buildSidebarItem('database', 'Database & Reset', Icons.storage_rounded, theme),
              _buildSidebarItem('about', 'About Information', Icons.info_outline_rounded, theme),
            ],
          ),
        ),
        // Active Section Detail Area (70% Width)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: _buildActiveSectionContent(theme, themeProvider, l10n),
          ),
        ),
      ],
    );
  }

  // ── MOBILE COMPACT SINGLE COLUMN LAYOUT ──────────────────
  Widget _buildMobileLayout(AppThemeType theme, ThemeProvider themeProvider, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileSection('Playback & Video', Icons.play_circle_filled_rounded, _buildPlaybackSettings(theme, l10n), theme),
          const SizedBox(height: 16),
          _buildMobileSection('Theme & Color', Icons.palette_rounded, _buildThemeSettings(theme, themeProvider), theme),
          const SizedBox(height: 16),
          _buildMobileSection('API & Metadata', Icons.auto_awesome_rounded, _buildApiSettings(theme, l10n), theme),
          const SizedBox(height: 16),
          _buildMobileSection('Parental Lock', Icons.lock_rounded, _buildParentalSettings(theme, l10n), theme),
          const SizedBox(height: 16),
          _buildMobileSection('Database & Reset', Icons.storage_rounded, _buildDatabaseSettings(theme, l10n), theme),
          const SizedBox(height: 16),
          _buildMobileSection('About Information', Icons.info_outline_rounded, _buildAboutSettings(theme, l10n), theme),
        ],
      ),
    );
  }

  // ── RENDER SIDEBAR SELECTOR TILE ─────────────────────────
  Widget _buildSidebarItem(String sectionId, String label, IconData icon, AppThemeType theme) {
    final bool isActive = _activeSection == sectionId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeSection = sectionId),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isActive ? theme.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? theme.accentPrimary.withValues(alpha: 0.25) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? theme.accentPrimary : theme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : theme.textSecondary,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── RENDER COMPACT MOBILE SECTION CARD ───────────────────
  Widget _buildMobileSection(String title, IconData icon, Widget child, AppThemeType theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.accentPrimary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
        ),
        iconColor: theme.accentPrimary,
        collapsedIconColor: theme.textSecondary,
        childrenPadding: const EdgeInsets.all(16),
        shape: const Border(),
        children: [child],
      ),
    );
  }

  // ── ROUTE DIRECT ACTIVE PANEL CONTENT ───────────────────
  Widget _buildActiveSectionContent(AppThemeType theme, ThemeProvider themeProvider, AppLocalizations l10n) {
    switch (_activeSection) {
      case 'playback':
        return _buildPlaybackSettings(theme, l10n);
      case 'appearance':
        return _buildThemeSettings(theme, themeProvider);
      case 'api':
        return _buildApiSettings(theme, l10n);
      case 'parental':
        return _buildParentalSettings(theme, l10n);
      case 'database':
        return _buildDatabaseSettings(theme, l10n);
      case 'about':
        return _buildAboutSettings(theme, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── SECTION: PLAYBACK & VIDEO ────────────────────────────
  Widget _buildPlaybackSettings(AppThemeType theme, AppLocalizations l10n) {
    return _buildContainerCard(theme, [
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
    ]);
  }

  // ── SECTION: THEME & COLOR GRID ─────────────────────────
  Widget _buildThemeSettings(AppThemeType theme, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.3)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: AppThemeType.values.length,
        itemBuilder: (context, index) {
          final themeOption = AppThemeType.values[index];
          final isSelected = themeProvider.currentTheme == themeOption;
          
          return InkWell(
            onTap: () => themeProvider.setTheme(themeOption),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: themeOption.backgroundPrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? theme.accentPrimary : theme.borderPrimary.withValues(alpha: 0.3),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: theme.accentPrimary.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 6))
                ] : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: themeOption.accentPrimary,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      themeOption.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        letterSpacing: 0.2,
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

  // ── SECTION: API & METADATA INTEGRATIONS ─────────────────
  Widget _buildApiSettings(AppThemeType theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: theme.accentPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              const Text(
                'API Optimization',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetApiKeys,
                style: TextButton.styleFrom(
                  backgroundColor: theme.accentPrimary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('RESET', style: TextStyle(color: theme.accentPrimary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Enhance metadata processing for M3U playlists with external API integration.',
            style: TextStyle(color: theme.textSecondary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 28),
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
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: theme.primaryGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveApiKeys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                label: const Text('SAVE API CONFIGURATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION: PARENTAL CONTROL & SECURITY ─────────────────
  Widget _buildParentalSettings(AppThemeType theme, AppLocalizations l10n) {
    return _buildContainerCard(theme, [
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
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.vpn_key_rounded, color: theme.accentPrimary, size: 20),
        ),
        title: const Text('Change Parental PIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: theme.accentPrimary, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () => _changeParentalPin(theme),
      ),
    ]);
  }

  // ── SECTION: DATABASE & RESET ───────────────────────────
  Widget _buildDatabaseSettings(AppThemeType theme, AppLocalizations l10n) {
    return _buildContainerCard(theme, [
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
        ),
        title: Text(l10n.clearAllData, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: Text(l10n.clearDataConfirm, style: TextStyle(color: theme.textSecondary, fontSize: 13)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () => _showClearDataDialog(theme),
      ),
    ]);
  }

  // ── SECTION: ABOUT SPECIFICATIONS ──────────────────────
  Widget _buildAboutSettings(AppThemeType theme, AppLocalizations l10n) {
    return _buildContainerCard(theme, [
      _buildInfoTile(Icons.info_outline_rounded, l10n.version, '1.2.0', theme),
      _buildInfoTile(Icons.code_rounded, 'Framework', 'Flutter SDK', theme),
      _buildInfoTile(Icons.storage_rounded, 'Engine', 'Media Kit + Isar', theme),
    ]);
  }

  // ── HELPER CONTAINER TILE WIDGETS ────────────────────────
  Widget _buildContainerCard(AppThemeType theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.3)),
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
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.accentPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: theme.accentPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
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
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: theme.accentPrimary,
      activeTrackColor: theme.accentPrimary.withValues(alpha: 0.2),
      inactiveTrackColor: theme.backgroundTertiary,
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
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: SliderTheme(
        data: SliderThemeData(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          value: value,
          onChanged: onChanged,
          activeColor: theme.accentPrimary,
          inactiveColor: theme.borderPrimary.withValues(alpha: 0.3),
        ),
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
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      trailing: Text(value, style: TextStyle(color: theme.accentPrimary.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.3)),
            filled: true,
            fillColor: theme.backgroundTertiary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.borderPrimary.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.accentPrimary.withValues(alpha: 0.5))),
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

  // --- Dialog Selections & Prompts ---

  void _selectQuality(AppLocalizations l10n, AppThemeType theme) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: theme.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.selectQuality, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        children: ['auto', '1080p', '720p', '480p'].map((q) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, q),
          child: Text(q.toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.selectVideoFit, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        children: ['contain', 'cover', 'fitWidth', 'fitHeight'].map((f) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, f),
          child: Text(f.toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        )).toList(),
      ),
    );
    if (result != null) setState(() => _videoFit = result);
  }

  Future<void> _showPinDialog(AppThemeType theme) async {
     final l10n = AppLocalizations.of(context);
     final currentPin = await PreferencesService.getParentalPin();
     final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(l10n.enterPin, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n.enter4DigitPin, 
              hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5)),
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
    if (pin == currentPin) {
      setState(() => _showAdultContent = true);
    } else if (pin != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.incorrectPin)));
      }
    }
  }

  Future<void> _changeParentalPin(AppThemeType theme) async {
    final l10n = AppLocalizations.of(context);
    final currentPin = await PreferencesService.getParentalPin();

    // First, verify current PIN
    if (!mounted) return;
    final currentInput = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Verify Current PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter current PIN',
              hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5)),
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

    if (currentInput != currentPin) {
      if (currentInput != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.incorrectPin)));
      }
      return;
    }

    // Now, enter new PIN
    if (!mounted) return;
    final newPin = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Set New PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter new 4-digit PIN',
              hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.borderPrimary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentPrimary)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentPrimary, foregroundColor: Colors.black),
              child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    if (newPin != null && newPin.length == 4) {
      await PreferencesService.setParentalPin(newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parental Control PIN changed successfully')));
      }
    } else if (newPin != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be exactly 4 digits')));
      }
    }
  }

  Future<void> _showClearDataDialog(AppThemeType theme) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.clearAllData, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
