import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../widgets/language_selector.dart';
import '../widgets/content_widgets.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import 'mobile_live_tv_screen.dart';
import 'mobile_movies_screen.dart';
import 'mobile_series_screen.dart';
import 'playlist_manager_screen.dart';
import 'settings_screen.dart';
import 'profiles_screen.dart';
import 'epg_screen.dart';
import 'mobile_video_player_screen.dart';

class MobileDashboardScreen extends StatefulWidget {
  final bool showWelcomeDialog;

  const MobileDashboardScreen({Key? key, this.showWelcomeDialog = false}) : super(key: key);

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  Profile? _activeProfile;
  Playlist? _activePlaylist;
  List<Playlist> _availablePlaylists = [];
  List<Channel> _recentChannels = [];
  List<Channel> _favoriteChannels = [];
  int _totalChannels = 0;
  int _totalMovies = 0;
  int _totalSeries = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Allow both orientations for better mobile experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Keep default orientations
    super.dispose();
  }

  Future<void> _loadData() async {
    final activePlaylistId = await PreferencesService.getActivePlaylistId();
    final profiles = await DatabaseService.getAllProfiles();

    Profile? activeProfile;
    if (profiles.isNotEmpty) {
      activeProfile = await DatabaseService.getActiveProfile();
    }

    final playlists = await DatabaseService.getAllPlaylists();
    Playlist? activePlaylist;
    if (activePlaylistId != null) {
      activePlaylist = await DatabaseService.getPlaylistById(activePlaylistId);
    }

    final allChannels = activePlaylistId != null 
        ? await DatabaseService.getChannelsByPlaylistId(activePlaylistId)
        : await DatabaseService.getAllChannels();
    final recent = await DatabaseService.getRecentlyPlayedChannels(limit: 10);
    final favorites = await DatabaseService.getFavoriteChannels();

    if (mounted) {
      setState(() {
        _activeProfile = activeProfile;
        _activePlaylist = activePlaylist ?? (playlists.isNotEmpty ? playlists.first : null);
        _availablePlaylists = playlists;
        _recentChannels = recent;
        _favoriteChannels = favorites;
        _totalChannels = allChannels.where((c) => c.contentType == ContentType.live).length;
        _totalMovies = allChannels.where((c) => c.contentType == ContentType.movie).length;
        _totalSeries = allChannels.where((c) => c.contentType == ContentType.series).length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(l10n, theme),
              const SizedBox(height: 32),
              
              // Top Grid and Quick Menu
              if (isPortrait) ...[
                // Vertical layout for portrait
                Row(
                  children: [
                    Expanded(
                      child: _buildLargeNavCard(
                        l10n.liveTV,
                        '${_totalChannels} Channels',
                        Icons.live_tv_rounded,
                        theme.accentPrimary,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileLiveTVScreen())),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLargeNavCard(
                        l10n.movies,
                        '${_totalMovies} Movies',
                        Icons.movie_rounded,
                        const Color(0xFF4CAF50),
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileMoviesScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildLargeNavCard(
                        l10n.series,
                        '${_totalSeries} Series',
                        Icons.movie_filter_rounded,
                        const Color(0xFFFF9800),
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileSeriesScreen())),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildQuickActionItem(l10n.playlistManager, Icons.playlist_add_check_rounded, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistManagerScreen())).then((_) => _loadData());
                          }, theme),
                          const SizedBox(height: 12),
                          _buildQuickActionItem(l10n.refresh, Icons.refresh_rounded, _loadData, theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Horizontal layout for landscape
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Category Cards
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildLargeNavCard(
                              l10n.liveTV,
                              '${_totalChannels} Channels',
                              Icons.live_tv_rounded,
                              theme.accentPrimary,
                              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileLiveTVScreen())),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildLargeNavCard(
                              l10n.movies,
                              '${_totalMovies} Movies',
                              Icons.movie_rounded,
                              const Color(0xFF4CAF50),
                              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileMoviesScreen())),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildLargeNavCard(
                              l10n.series,
                              '${_totalSeries} Series',
                              Icons.movie_filter_rounded,
                              const Color(0xFFFF9800),
                              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileSeriesScreen())),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Quick Actions List
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildQuickActionItem(l10n.playlistManager, Icons.playlist_add_check_rounded, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistManagerScreen())).then((_) => _loadData());
                          }, theme),
                          const SizedBox(height: 12),
                          _buildQuickActionItem(l10n.epgGuide, Icons.calendar_today_rounded, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const EpgScreen()));
                          }, theme),
                          const SizedBox(height: 12),
                          _buildQuickActionItem(l10n.refresh, Icons.refresh_rounded, _loadData, theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 48),

              // Continue Watching Section
              if (_recentChannels.isNotEmpty) ...[
                _buildSectionHeader(l10n.continueWatching, Icons.history_rounded, theme),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    clipBehavior: Clip.none,
                    itemCount: _recentChannels.length,
                    itemBuilder: (context, index) {
                      return _buildLandscapeContentCard(_recentChannels[index], theme, showProgress: true);
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],

              // Favorites Section
              if (_favoriteChannels.isNotEmpty) ...[
                _buildSectionHeader(l10n.myFavorites, Icons.favorite_rounded, theme),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    clipBehavior: Clip.none,
                    itemCount: _favoriteChannels.length,
                    itemBuilder: (context, index) {
                      return _buildFavoriteCircleCard(_favoriteChannels[index], theme);
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(AppLocalizations l10n, AppThemeType theme) {
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('MMMM dd, yyyy').format(now);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tv_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _activePlaylist?.name ?? 'RIPTV',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            Text(
              '$timeStr | $dateStr',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        _buildCircularHeaderButton(Icons.person_rounded, () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilesScreen()));
          _loadData();
        }),
        const SizedBox(width: 12),
        _buildCircularHeaderButton(Icons.settings_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        }),
      ],
    );
  }

  Widget _buildCircularHeaderButton(IconData icon, VoidCallback onTap) {
    return _FocusableButton(
      onTap: onTap,
      builder: (context, focused) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: focused ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLargeNavCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return _FocusableButton(
      onTap: onTap,
      builder: (context, focused) => AnimatedScale(
        scale: focused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: focused ? const Color(0xFF252545) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: focused ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.05), width: focused ? 2 : 1),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 24,
                left: 24,
                child: Icon(icon, color: Colors.white.withOpacity(focused ? 0.2 : 0.1), size: 64),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: title.split(' ')[0],
                            style: TextStyle(color: focused ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          if (title.contains(' '))
                            TextSpan(
                              text: ' ${title.split(' ')[1]}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(color: focused ? Colors.white : Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.white.withOpacity(focused ? 0.8 : 0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(String label, IconData icon, VoidCallback onTap, AppThemeType theme) {
    return _FocusableButton(
      onTap: onTap,
      builder: (context, focused) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: focused ? theme.accentPrimary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: focused ? theme.accentPrimary : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: focused ? Colors.white : Colors.white.withOpacity(0.6), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: focused ? Colors.white : Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, AppThemeType theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.accentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.accentPrimary, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.accentPrimary.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeContentCard(Channel channel, AppThemeType theme, {bool showProgress = false}) {
    return _FocusableButton(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MobileVideoPlayerScreen(channel: channel)))
          .then((_) => _loadData());
      },
      builder: (context, focused) => Container(
        width: 300,
        margin: const EdgeInsets.only(right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E32),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: focused ? theme.accentPrimary : Colors.white.withOpacity(0.05), width: 2),
                  boxShadow: [
                    if (focused) BoxShadow(color: theme.accentPrimary.withOpacity(0.3), blurRadius: 15),
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                  image: channel.logo != null && channel.logo!.isNotEmpty ? DecorationImage(
                    image: NetworkImage(channel.logo!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (channel.logo == null || channel.logo!.isEmpty)
                      const Center(child: Icon(Icons.movie_rounded, color: Colors.white10, size: 56)),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                          channel.contentType == ContentType.live ? Icons.live_tv_rounded : Icons.play_arrow_rounded,
                          color: Colors.white, 
                          size: 16
                        ),
                      ),
                    ),
                    if (showProgress)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.65,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.accentPrimary,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              channel.name,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: focused ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: -0.2
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              channel.group ?? 'Category',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCircleCard(Channel channel, AppThemeType theme) {
    return _FocusableButton(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MobileVideoPlayerScreen(channel: channel)))
          .then((_) => _loadData());
      },
      builder: (context, focused) => Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: focused ? theme.accentPrimary : Colors.transparent, width: 2),
                  image: channel.logo != null && channel.logo!.isNotEmpty ? DecorationImage(
                    image: NetworkImage(channel.logo!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: channel.logo == null || channel.logo!.isEmpty
                  ? const Center(child: Icon(Icons.movie_rounded, color: Colors.white10, size: 40))
                  : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              channel.name,
              style: TextStyle(color: focused ? theme.accentPrimary : Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusableButton extends StatefulWidget {
  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback onTap;

  const _FocusableButton({required this.builder, required this.onTap});

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
      onShowFocusHighlight: (val) => setState(() => _isFocused = val),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.builder(context, _isFocused),
      ),
    );
  }
}
