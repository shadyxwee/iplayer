import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'live_tv_screen.dart';
import 'playlist_manager_screen.dart';
import 'settings_screen.dart';
import 'content_grid_screen.dart';
import 'series_grid_screen.dart';
import 'profiles_screen.dart';
import 'epg_screen.dart';
import 'video_player_screen.dart';
import 'mobile_live_tv_screen.dart';
import 'mobile_movies_screen.dart';
import 'mobile_series_screen.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../services/tmdb_service.dart';
import '../services/preferences_service.dart';
import '../widgets/welcome_dialog.dart';
import '../widgets/language_selector.dart';
import '../widgets/theme_selector.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive.dart';
import '../providers/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  final bool showWelcomeDialog;

  const DashboardScreen({Key? key, this.showWelcomeDialog = false}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Profile? _activeProfile;
  Playlist? _activePlaylist;
  List<Playlist> _availablePlaylists = [];
  List<Channel> _recentChannels = [];
  List<Channel> _favoriteChannels = [];
  int _totalChannels = 0;
  int _totalMovies = 0;
  int _totalSeries = 0;
  late AppLocalizations l10n;

  // Avatar options (same as ProfilesScreen)
  final List<IconData> _avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.child_care,
    Icons.elderly,
    Icons.pets,
    Icons.sports_esports,
    Icons.music_note,
    Icons.movie,
    Icons.sports_soccer,
    Icons.star,
    Icons.favorite,
    Icons.emoji_emotions,
  ];

  final List<Color> _avatarColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadActiveProfile();
    _loadPlaylists();
    _loadDashboardData();

    // Show welcome dialog if it's the first launch
    if (widget.showWelcomeDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const WelcomeDialog(),
        );
      });
    }
  }

  Future<void> _loadActiveProfile() async {
    final profile = await DatabaseService.getActiveProfile();
    setState(() => _activeProfile = profile);
  }

  Future<void> _loadPlaylists() async {
    final allPlaylists = await DatabaseService.getAllPlaylists();
    final activePlaylistId = await PreferencesService.getActivePlaylistId();

    Playlist? activePlaylist;
    if (activePlaylistId != null) {
      activePlaylist = await DatabaseService.getPlaylistById(activePlaylistId);
    }

    setState(() {
      _availablePlaylists = allPlaylists;
      _activePlaylist = activePlaylist ?? (allPlaylists.isNotEmpty ? allPlaylists.first : null);
    });
  }

  Future<void> _loadDashboardData() async {
    List<Channel> allChannels;

    // Filter by active playlist if one is selected
    if (_activePlaylist != null) {
      allChannels = await DatabaseService.getChannelsByPlaylistId(_activePlaylist!.id);
    } else {
      allChannels = await DatabaseService.getAllChannels();
    }

    final recent = await DatabaseService.getRecentlyPlayedChannels(limit: 6);
    // Filter recent by active playlist
    if (_activePlaylist != null) {
      recent.retainWhere((c) => c.playlistId == _activePlaylist!.id);
    }

    final favorites = allChannels.where((c) => c.isFavorite).take(12).toList();

    // Assign ratings immediately for all movies/series
    _assignRatingsSync(recent);
    _assignRatingsSync(favorites);

    setState(() {
      _recentChannels = recent;
      _favoriteChannels = favorites;
      _totalChannels = allChannels.where((c) => c.contentType == ContentType.live).length;
      _totalMovies = allChannels.where((c) => c.contentType == ContentType.movie).length;
      _totalSeries = allChannels.where((c) => c.contentType == ContentType.series).length;
    });

    // Save ratings to database asynchronously
    _saveRatingsToDatabase(recent + favorites);
  }

  /// Assign ratings synchronously from cache/fallback
  void _assignRatingsSync(List<Channel> channels) {
    // Rely on grid and details screens for enhanced metadata
  }

  /// No longer Generating pseudo-random ratings to maintain data integrity
  double? _getRatingSync(String contentName, bool isMovie) {
    return 0.0;
  }

  /// Save ratings to database asynchronously
  Future<void> _saveRatingsToDatabase(List<Channel> channels) async {
    for (final channel in channels) {
      if (channel.rating > 0) {
        try {
          await DatabaseService.updateChannelRating(channel, channel.rating);
        } catch (e) {
          print('Error saving rating for ${channel.name}: $e');
        }
      }
    }
  }

  Future<void> _setActivePlaylist(Playlist playlist) async {
    await PreferencesService.setActivePlaylistId(playlist.id);
    setState(() => _activePlaylist = playlist);
    _loadDashboardData();
  }

  Widget _buildPlaylistSelector(AppThemeType theme, AppLocalizations l10n) {
    if (_availablePlaylists.isEmpty) {
      return TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlaylistManagerScreen(),
            ),
          ).then((_) {
            _loadPlaylists();
            _loadDashboardData();
          });
        },
        icon: Icon(Icons.add_to_queue, color: theme.textPrimary),
        label: Text(l10n.addPlaylist, style: TextStyle(color: theme.textPrimary)),
      );
    }

    return PopupMenuButton<Playlist>(
      initialValue: _activePlaylist,
      onSelected: _setActivePlaylist,
      itemBuilder: (context) {
        return [
          ..._availablePlaylists.map((playlist) {
            final isActive = playlist.id == _activePlaylist?.id;
            return PopupMenuItem(
              value: playlist,
              child: Row(
                children: [
                  if (isActive)
                    const Icon(Icons.check, color: Colors.green, size: 16)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(playlist.name, style: TextStyle(color: theme.textPrimary)),
                        Text(
                          l10n.channelsCountShort(playlist.channelCount),
                          style: TextStyle(color: theme.textSecondary.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const PopupMenuDivider(),
          PopupMenuItem(
            child: Text(l10n.managePlaylists, style: TextStyle(color: theme.textPrimary)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaylistManagerScreen(),
                ),
              ).then((_) {
                _loadPlaylists();
                _loadDashboardData();
              });
            },
          ),
        ];
      },
      color: theme.backgroundTertiary,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.textPrimary.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_play, color: theme.textPrimary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _activePlaylist?.name ?? l10n.noPlaylist,
                style: TextStyle(color: theme.textPrimary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: theme.textPrimary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(AppThemeType theme, {double size = 32}) {
    if (_activeProfile == null) {
      return Icon(Icons.person_outline, color: theme.textPrimary, size: size * 0.7);
    }

    int iconIndex = 0;
    int colorIndex = 0;

    if (_activeProfile!.avatarUrl != null && _activeProfile!.avatarUrl!.contains('_')) {
      final parts = _activeProfile!.avatarUrl!.split('_');
      iconIndex = int.tryParse(parts[0]) ?? 0;
      colorIndex = int.tryParse(parts[1]) ?? 0;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarColors[colorIndex.clamp(0, _avatarColors.length - 1)],
        shape: BoxShape.circle,
      ),
      child: Icon(
        _avatarIcons[iconIndex.clamp(0, _avatarIcons.length - 1)],
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final bool isMobile = Responsive.isMobile(context);
    final EdgeInsets padding = Responsive.getPadding(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          // Add drawer for mobile navigation
          drawer: isMobile ? _buildMobileDrawer(l10n) : null,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Hero Container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(isMobile, EdgeInsets.zero, theme, l10n),
                        
                        const SizedBox(height: 24),

                        // Hero Navigation Section (includes Utility Hub on desktop)
                        _buildHeroNavigation(l10n, theme, isMobile),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Continue Watching Section
                  if (_recentChannels.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Continue Watching', 
                      Icons.history, 
                      theme,
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentChannels.length,
                        itemBuilder: (context, index) {
                          return _buildContinueWatchingCard(_recentChannels[index], theme);
                        },
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],

                  // Favorites Section
                  if (_favoriteChannels.isNotEmpty) ...[
                    _buildSectionHeader(
                      'My Favorites', 
                      Icons.favorite_rounded, 
                      theme,
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _favoriteChannels.length,
                        itemBuilder: (context, index) {
                          return _buildFavoriteCard(_favoriteChannels[index], theme);
                        },
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                  
                  // Footer Info
                  Center(
                    child: Column(
                      children: [
                        _buildDedicationMessage(theme, l10n),
                        const SizedBox(height: 24),
                        Text(
                          l10n.versionLabel('1.0.0'),
                          style: TextStyle(
                            color: theme.textSecondary.withOpacity(0.3),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(Channel channel, AppThemeType theme) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(channel: channel)))
                .then((_) => _loadDashboardData());
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    image: channel.logo != null && channel.logo!.isNotEmpty ? DecorationImage(
                      image: NetworkImage(channel.logo!),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    ) : null,
                  ),
                  child: channel.logo == null || channel.logo!.isEmpty
                    ? Center(child: Icon(Icons.movie_rounded, color: theme.textSecondary.withOpacity(0.2), size: 48))
                    : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                channel.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                channel.group ?? 'Channel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueWatchingCard(Channel channel, AppThemeType theme) {
    // Generate some mock progress for the demo
    final double progress = 0.3 + (Random().nextDouble() * 0.5);
    final int timeLeft = 10 + Random().nextInt(50);

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(channel: channel)))
                .then((_) => _loadDashboardData());
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        image: channel.logo != null && channel.logo!.isNotEmpty ? DecorationImage(
                          image: NetworkImage(channel.logo!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ) : null,
                      ),
                      child: channel.logo == null || channel.logo!.isEmpty
                        ? Center(child: Icon(Icons.movie_rounded, color: theme.textSecondary.withOpacity(0.2), size: 48))
                        : null,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0),
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.accentPrimary,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.name,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          channel.group ?? 'Content',
                          style: TextStyle(
                            color: theme.textSecondary.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: theme.textSecondary.withOpacity(0.4), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$timeLeft min left',
                        style: TextStyle(
                          color: theme.textSecondary.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTrendingChannelCard(Channel channel, AppThemeType theme) {
    // Mock viewer count
    final viewers = (1 + Random().nextDouble() * 9).toStringAsFixed(1);
    
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(channel: channel)));
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.borderPrimary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.accentPrimary.withOpacity(0.1),
                      backgroundImage: channel.logo != null && channel.logo!.isNotEmpty
                        ? NetworkImage(channel.logo!)
                        : null,
                      child: channel.logo == null || channel.logo!.isEmpty
                        ? Icon(Icons.tv_rounded, color: theme.accentPrimary)
                        : null,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.backgroundPrimary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  channel.name,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  channel.group ?? 'Channel',
                  style: TextStyle(
                    color: theme.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
                const Spacer(),
                Text(
                  '${viewers}K viewers',
                  style: TextStyle(
                    color: theme.accentPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }





  Widget _buildHeader(bool isMobile, EdgeInsets padding, AppThemeType theme, AppLocalizations l10n) {
    return Row(
      children: [
        _buildLogo(theme),
        const Spacer(),
        if (!isMobile) ...[
          _buildTopActionButton(Icons.person_rounded, () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilesScreen()),
            );
            if (result != null) _loadActiveProfile();
          }),
          const SizedBox(width: 12),
          _buildHeaderActions(l10n, theme),
        ],
      ],
    );
  }

  Widget _buildHeaderActions(AppLocalizations l10n, AppThemeType theme) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
      ),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        switch (value) {
          case 'search':
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
            break;
          case 'refresh':
            _loadDashboardData();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.playlistUpdated)));
            break;
          case 'language':
            showDialog(context: context, builder: (context) => const LanguageSelector());
            break;
          case 'playlists':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistManagerScreen()));
            break;
          case 'epg':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EpgScreen()));
            break;
          case 'settings':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            break;
          case 'logout':
            _showExitDialog(l10n, theme);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'search', child: _buildPopupItem(theme, Icons.search, l10n.search)),
        PopupMenuItem(value: 'refresh', child: _buildPopupItem(theme, Icons.refresh, l10n.refresh)),
        PopupMenuItem(value: 'playlists', child: _buildPopupItem(theme, Icons.playlist_play_rounded, l10n.playlists)),
        PopupMenuItem(value: 'epg', child: _buildPopupItem(theme, Icons.calendar_month_rounded, l10n.epgGuide)),
        PopupMenuItem(value: 'language', child: _buildPopupItem(theme, Icons.language, l10n.language)),
        PopupMenuItem(value: 'settings', child: _buildPopupItem(theme, Icons.tune, l10n.settings)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: _buildPopupItem(theme, Icons.logout, l10n.exit, color: Colors.redAccent)),
      ],
    );
  }

  Widget _buildLogo(AppThemeType theme) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tv_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'RIPTV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_getCurrentTime()} | ${_getCurrentDate()}',
              style: const TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroNavigation(AppLocalizations l10n, AppThemeType theme, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildModernNavCard(
                'Live TV',
                _totalChannels.toString(),
                'Channels',
                'live',
                const Color(0xFFE53935),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveTVScreen()))
                    .then((_) => _loadDashboardData()),
                theme,
              ),
              const SizedBox(width: 16),
              _buildModernNavCard(
                'Movies',
                _totalMovies.toString(),
                'Movies',
                'movies',
                Colors.white,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContentGridScreen(contentType: ContentType.movie, title: l10n.movies)))
                    .then((_) => _loadDashboardData()),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildModernNavCard(
                'Series',
                _totalSeries.toString(),
                'Series',
                'series',
                Colors.white,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SeriesGridScreen()))
                    .then((_) => _loadDashboardData()),
                theme,
              ),
              const SizedBox(width: 16),
              _buildUtilityHubCard(theme, l10n, true),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 75% Width Content Area
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _buildModernNavCard(
                'Live TV',
                _totalChannels.toString(),
                'Channels',
                'live',
                const Color(0xFFE53935),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveTVScreen()))
                    .then((_) => _loadDashboardData()),
                theme,
              ),
              const SizedBox(width: 16),
              _buildModernNavCard(
                'Movies',
                _totalMovies.toString(),
                'Movies',
                'movies',
                Colors.white,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContentGridScreen(contentType: ContentType.movie, title: l10n.movies)))
                    .then((_) => _loadDashboardData()),
                theme,
              ),
              const SizedBox(width: 16),
              _buildModernNavCard(
                'Series',
                _totalSeries.toString(),
                'Series',
                'series',
                Colors.white,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SeriesGridScreen()))
                    .then((_) => _loadDashboardData()),
                theme,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Utility Hub (25%)
        Expanded(
          flex: 1,
          child: _buildUtilityHubCard(theme, l10n, false),
        ),
      ],
    );
  }

  Widget _buildUtilityHubCard(AppThemeType theme, AppLocalizations l10n, bool isMobile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUtilityItem(Icons.playlist_play_rounded, 'Playlist Manager', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistManagerScreen()));
        }),
        const SizedBox(height: 8),
        _buildUtilityItem(Icons.calendar_month_rounded, 'EPG', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EpgScreen()));
        }),
        const SizedBox(height: 8),
        _buildUtilityItem(Icons.refresh_rounded, 'Refresh Data', () {
          _loadDashboardData();
        }),
      ],
    );
  }

  Widget _buildUtilityItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF3A3A4E),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNavCard(
    String title,
    String count,
    String countLabel,
    String type,
    Color accentColor,
    VoidCallback onTap,
    AppThemeType theme,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardIcon(type),
                const Spacer(),
                if (type == 'live')
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Live ',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: 'Tv',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0x66FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count $countLabel',
                      style: const TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardIcon(String type) {
    switch (type) {
      case 'live':
        return SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(painter: RetroTVPainter()),
        );
      case 'movies':
        return SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(painter: PopcornPainter()),
        );
      case 'series':
        return SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(painter: ClapperboardPainter()),
        );
      default:
        return const Icon(Icons.category, size: 48, color: Colors.white);
    }
  }

  Widget _buildCombinedNavCard(
    String title,
    String count,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
    AppThemeType theme,
    bool isMobile,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.textPrimary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.textPrimary.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      color: theme.textSecondary.withOpacity(0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeWidget(AppThemeType theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _getCurrentTime(),
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          _getCurrentDate().toUpperCase(),
          style: TextStyle(
            color: theme.textSecondary.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumNavCard(
    String title,
    String count,
    String countLabel,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
    AppThemeType theme, {
    bool isLive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 180,
          height: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.backgroundTertiary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 44),
              const SizedBox(height: 24),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Live Tv',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                )
              else
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    '$count $countLabel',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroActionItem(IconData icon, String label, AppThemeType theme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 28),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100, // Fixed width for labels
            child: Text(
              label,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuickAccess(AppThemeType theme, AppLocalizations l10n) {
    return Column(
      children: [
        _buildSecondaryCard(l10n.playlists, Icons.playlist_play_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistManagerScreen()));
        }, theme),
        const SizedBox(height: 16),
        _buildSecondaryCard(l10n.configuration, Icons.tune_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        }, theme),
        const SizedBox(height: 16),
        _buildSecondaryCard(l10n.epgGuide, Icons.auto_awesome_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EpgScreen()));
        }, theme),
      ],
    );
  }

  Widget _buildDedicationMessage(AppThemeType theme, AppLocalizations l10n) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.borderPrimary.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l10n.appInspiration,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.favorite_rounded, color: Colors.redAccent.withOpacity(0.8), size: 18),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good Night';
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeroCard(
    String title,
    String count,
    String countLabel,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
    AppThemeType theme, {
    bool isLive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        hoverColor: Colors.white.withOpacity(0.02),
        splashColor: accentColor.withOpacity(0.1),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$count $countLabel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D5F8D).withOpacity(0.3),
                  const Color(0xFF1E3A5F).withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF2D5F8D).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.85),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(AppThemeType theme, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.textPrimary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _buildProfileAvatar(theme, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildPopupItem(AppThemeType theme, IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? theme.textPrimary.withOpacity(0.7), size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color ?? theme.textPrimary)),
      ],
    );
  }

  void _showExitDialog(AppLocalizations l10n, AppThemeType theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.exit, style: TextStyle(color: theme.textPrimary)),
        content: Text(l10n.confirmExit, style: TextStyle(color: theme.textSecondary.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.exit),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, AppThemeType theme, {VoidCallback? onViewAll}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View All',
                style: TextStyle(
                  color: theme.accentPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard(
    String title,
    IconData icon,
    VoidCallback onTap,
    AppThemeType theme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.borderPrimary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.accentPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: theme.accentPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: theme.cardTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard(Channel channel, AppThemeType theme) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(channel: channel),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.borderPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/Thumbnail section
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Stack(
                      children: [
                        Center(
                          child: channel.logo != null && channel.logo!.isNotEmpty
                              ? Image.network(
                                  channel.logo!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholderIcon(channel, theme),
                                )
                              : _buildPlaceholderIcon(channel, theme),
                        ),
                        // Play overlay with gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Play button
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.accentPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Info section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: TextStyle(
                          color: theme.cardTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (channel.group != null)
                        Text(
                          channel.group!,
                          style: TextStyle(
                            color: theme.cardTextSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Channel channel, AppThemeType theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.backgroundTertiary,
      child: Icon(
        channel.contentType == ContentType.live
            ? Icons.tv
            : channel.contentType == ContentType.movie
                ? Icons.movie
                : Icons.video_library,
        color: Colors.white.withOpacity(0.1),
        size: 48,
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);
    final amPm = now.hour >= 12 ? l10n.pm : l10n.am;
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);
    final monthNames = [
      l10n.january, l10n.february, l10n.march, l10n.april,
      l10n.may, l10n.june, l10n.july, l10n.august,
      l10n.september, l10n.october, l10n.november, l10n.december
    ];
    return '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Mobile drawer for navigation
  Widget _buildMobileDrawer(AppLocalizations l10n) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        return Drawer(
          backgroundColor: theme.sidebarBackground,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.primaryGradient,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tv_rounded, color: Colors.black, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'RIPTV',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_activeProfile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _activeProfile!.name,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildDrawerItem(
                icon: Icons.dashboard_rounded,
                title: l10n.dashboard,
                theme: theme,
                onTap: () => Navigator.pop(context),
              ),
              _buildDrawerItem(
                icon: Icons.live_tv_rounded,
                title: l10n.liveTV,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveTVScreen()));
                },
              ),
              _buildDrawerItem(
                icon: Icons.movie_rounded,
                title: l10n.movies,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ContentGridScreen(contentType: ContentType.movie, title: l10n.movies)));
                },
              ),
              _buildDrawerItem(
                icon: Icons.auto_awesome_motion_rounded,
                title: l10n.series,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SeriesGridScreen()));
                },
              ),
              Divider(color: theme.borderPrimary.withOpacity(0.5)),
              _buildDrawerItem(
                icon: Icons.playlist_play_rounded,
                title: l10n.playlists,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistManagerScreen()));
                },
              ),
              _buildDrawerItem(
                icon: Icons.calendar_month_rounded,
                title: l10n.epgGuide,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EpgScreen()));
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings_rounded,
                title: l10n.settings,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required AppThemeType theme,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.textSecondary, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) {
      return const Color(0xFF4CAF50); // Green for excellent
    } else if (rating >= 7.0) {
      return const Color(0xFF8BC34A); // Light green for very good
    } else if (rating >= 6.0) {
      return const Color(0xFFFFC107); // Amber for good
    } else if (rating >= 5.0) {
      return const Color(0xFFFF9800); // Orange for fair
    } else {
      return const Color(0xFFF44336); // Red for poor
    }
  }
}

class RetroTVPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // TV Body
    final bodyRect = Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.6);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)), paint);

    // Screen
    final screenRect = Rect.fromLTWH(size.width * 0.2, size.height * 0.4, size.width * 0.5, size.height * 0.4);
    canvas.drawRRect(RRect.fromRectAndRadius(screenRect, const Radius.circular(4)), paint);

    // Antenna
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3), Offset(size.width * 0.3, size.height * 0.1), paint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3), Offset(size.width * 0.7, size.height * 0.1), paint);

    // Knobs
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.45), 2, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.55), 2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PopcornPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Bucket
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.35);
    path.lineTo(size.width * 0.3, size.height * 0.9);
    path.lineTo(size.width * 0.7, size.height * 0.9);
    path.lineTo(size.width * 0.8, size.height * 0.35);
    path.close();
    canvas.drawPath(path, paint);

    // Stripes
    canvas.drawLine(Offset(size.width * 0.4, size.height * 0.4), Offset(size.width * 0.45, size.height * 0.9), paint);
    canvas.drawLine(Offset(size.width * 0.6, size.height * 0.4), Offset(size.width * 0.55, size.height * 0.9), paint);

    // Popcorn Puffs
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.25), 6, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), 7, paint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.25), 6, paint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.3), 5, paint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.3), 5, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ClapperboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Body
    final bodyRect = Rect.fromLTWH(size.width * 0.1, size.height * 0.4, size.width * 0.8, size.height * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)), paint);

    // Top part (Clapper)
    final clapperPath = Path();
    clapperPath.moveTo(size.width * 0.1, size.height * 0.35);
    clapperPath.lineTo(size.width * 0.9, size.height * 0.25);
    clapperPath.lineTo(size.width * 0.9, size.height * 0.35);
    clapperPath.lineTo(size.width * 0.1, size.height * 0.45);
    clapperPath.close();
    canvas.drawPath(clapperPath, paint);

    // Stripes on top
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.32), Offset(size.width * 0.4, size.height * 0.42), paint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3), Offset(size.width * 0.6, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width * 0.7, size.height * 0.28), Offset(size.width * 0.8, size.height * 0.38), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
