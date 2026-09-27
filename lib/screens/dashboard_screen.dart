import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../widgets/dashboard_graphics.dart';
import '../widgets/smooth_page_route.dart';
import '../widgets/welcome_dialog.dart';
import 'content_grid_screen.dart';
import 'epg_screen.dart';
import 'live_tv_screen.dart';
import 'playlist_manager_screen.dart';
import 'profiles_screen.dart';
import 'series_grid_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool showWelcomeDialog;

  const DashboardScreen({super.key, this.showWelcomeDialog = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Playlist? _activePlaylist;
  int _totalChannels = 0;
  int _totalMovies = 0;
  int _totalSeries = 0;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  // Focus nodes for D-Pad / Keyboard navigation
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _notifFocusNode = FocusNode();
  final FocusNode _profileFocusNode = FocusNode();
  final FocusNode _reloadFocusNode = FocusNode();
  final FocusNode _logoutFocusNode = FocusNode();

  final FocusNode _liveTvFocusNode = FocusNode();
  final FocusNode _moviesFocusNode = FocusNode();
  final FocusNode _seriesFocusNode = FocusNode();

  final FocusNode _playlistsBtnFocusNode = FocusNode();
  final FocusNode _catchUpBtnFocusNode = FocusNode();
  final FocusNode _favoritesBtnFocusNode = FocusNode();
  final FocusNode _settingsBtnFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    _loadDashboardData();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

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

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchController.dispose();

    _searchFocusNode.dispose();
    _notifFocusNode.dispose();
    _profileFocusNode.dispose();
    _reloadFocusNode.dispose();
    _logoutFocusNode.dispose();

    _liveTvFocusNode.dispose();
    _moviesFocusNode.dispose();
    _seriesFocusNode.dispose();

    _playlistsBtnFocusNode.dispose();
    _catchUpBtnFocusNode.dispose();
    _favoritesBtnFocusNode.dispose();
    _settingsBtnFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final allPlaylists = await DatabaseService.getAllPlaylists();
    final activePlaylistId = await PreferencesService.getActivePlaylistId();

    Playlist? activePlaylist;
    if (activePlaylistId != null) {
      activePlaylist = await DatabaseService.getPlaylistById(activePlaylistId);
    }

    if (mounted) {
      setState(() {
        _activePlaylist = activePlaylist ?? (allPlaylists.isNotEmpty ? allPlaylists.first : null);
      });
    }
  }

  Future<void> _loadDashboardData() async {
    List<Channel> allChannels;

    if (_activePlaylist != null) {
      allChannels = await DatabaseService.getChannelsByPlaylistId(_activePlaylist!.id);
    } else {
      allChannels = await DatabaseService.getAllChannels();
    }

    if (mounted) {
      setState(() {
        _totalChannels = allChannels.where((c) => c.contentType == ContentType.live).length;
        _totalMovies = allChannels.where((c) => c.contentType == ContentType.movie).length;
        _totalSeries = allChannels.where((c) => c.contentType == ContentType.series).length;
      });
    }
  }

  String _getFormattedTime() {
    int hour = _now.hour;
    final minutes = _now.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minutes $ampm';
  }

  String _getFormattedDate() {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final dayName = days[_now.weekday % 7];
    final monthName = months[_now.month - 1];
    return '$dayName, $monthName ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF111022),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF17152F),
              Color(0xFF0D0C1B),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeader(context, l10n),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: _buildMainContentGrid(context, l10n),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Section: Logo & Time info
        Row(
          children: [
            // App Brand Logo Icon
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        Color(0xFF4338CA),
                        Color(0xFF4F46E5),
                        Color(0xFF9333EA),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1B4B).withValues(alpha: 0.6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF818CF8).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tv, color: Colors.white, size: 16),
                      SizedBox(height: 1),
                      Text(
                        'VORTEX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      Text(
                        'IPTV',
                        style: TextStyle(
                          color: Color(0xFFC7D2FE),
                          fontSize: 6,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'VIPTV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Live Clock & Date Display
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0x99334155), width: 1),
                ),
              ),
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getFormattedTime(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    _getFormattedDate(),
                    style: const TextStyle(
                      color: Color(0xFF8F92A9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Right Section: Search & Quick Utility Controls
        Row(
          children: [
            // Search Input Pill
            Focus(
              focusNode: _searchFocusNode,
              child: Builder(builder: (context) {
                final isFocused = Focus.of(context).hasFocus;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isFocused ? 256 : 224,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1D34),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused ? const Color(0xFF6366F1) : const Color(0xFF2E2B52),
                      width: isFocused ? 1.5 : 1.0,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              Navigator.push(
                                context,
                                SmoothPageRoute(
                                  child: ContentGridScreen(
                                    contentType: ContentType.live,
                                    title: 'Search: $value',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(width: 14),

            // Action Button: Notifications
            _buildHeaderIconButton(
              focusNode: _notifFocusNode,
              icon: Icons.notifications,
              hasBadge: true,
              tooltip: 'Notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications')),
                );
              },
            ),
            const SizedBox(width: 10),

            // Action Button: User Profile
            _buildHeaderIconButton(
              focusNode: _profileFocusNode,
              icon: Icons.person,
              tooltip: 'Account',
              onTap: () async {
                await Navigator.push(
                  context,
                  SmoothPageRoute(child: const ProfilesScreen()),
                );
              },
            ),
            const SizedBox(width: 10),

            // Action Button: Reload / Sync
            _buildHeaderIconButton(
              focusNode: _reloadFocusNode,
              icon: Icons.refresh,
              tooltip: 'Reload Playlist',
              onTap: () {
                _loadDashboardData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.playlistUpdated)),
                );
              },
            ),
            const SizedBox(width: 10),

            // Action Button: Logout / Exit
            _buildHeaderIconButton(
              focusNode: _logoutFocusNode,
              icon: Icons.logout,
              tooltip: 'Exit / Switch User',
              onTap: () => _showExitDialog(l10n),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required FocusNode focusNode,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool hasBadge = false,
  }) {
    bool isHovered = false;

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.select) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: StatefulBuilder(
        builder: (context, setState) {
          final isFocused = Focus.of(context).hasFocus;
          final active = isFocused || isHovered;

          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: tooltip,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF282645) : const Color(0xFF1E1D34),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? const Color(0xFF6366F1) : const Color(0xFF2E2B52),
                      width: active ? 2 : 1,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        icon,
                        color: active ? Colors.white : const Color(0xFFCBD5E1),
                        size: 20,
                      ),
                      if (hasBadge)
                        Positioned(
                          top: 9,
                          right: 9,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1E1D34), width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContentGrid(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT SECTION: 3 Primary Feature Cards (Live TV, Movies, Series) - 75% width
          Expanded(
            flex: 9,
            child: Row(
              children: [
                // Card 1: Live TV
                Expanded(
                  child: _buildPrimaryCard(
                    focusNode: _liveTvFocusNode,
                    graphic: const DashboardTvGraphic(size: 112),
                    badgeText: 'LIVE',
                    titleText: 'TV',
                    counterText: '$_totalChannels Channels',
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(child: const LiveTVScreen()),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                ),
                const SizedBox(width: 24),

                // Card 2: Movies
                Expanded(
                  child: _buildPrimaryCard(
                    focusNode: _moviesFocusNode,
                    graphic: const DashboardMoviesGraphic(size: 112),
                    titleText: 'Movies',
                    counterText: '$_totalMovies Movies',
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(
                          child: ContentGridScreen(
                            contentType: ContentType.movie,
                            title: l10n.movies,
                          ),
                        ),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                ),
                const SizedBox(width: 24),

                // Card 3: Series
                Expanded(
                  child: _buildPrimaryCard(
                    focusNode: _seriesFocusNode,
                    graphic: const DashboardSeriesGraphic(size: 112),
                    titleText: 'Series',
                    counterText: '$_totalSeries Series',
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(child: const SeriesGridScreen()),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // RIGHT SECTION: Stacked Navigation Actions List matching cards height - 25% width
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSideButton(
                  focusNode: _playlistsBtnFocusNode,
                  icon: Icons.format_list_bulleted,
                  title: 'Playlists',
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(child: const PlaylistManagerScreen()),
                    ).then((_) {
                      _loadPlaylists();
                      _loadDashboardData();
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildSideButton(
                  focusNode: _catchUpBtnFocusNode,
                  icon: Icons.history,
                  title: 'Catch Up',
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(child: const EpgScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildSideButton(
                  focusNode: _favoritesBtnFocusNode,
                  icon: Icons.movie_outlined,
                  title: 'Favorites',
                  isFavoritesIcon: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        child: ContentGridScreen(
                          contentType: ContentType.live,
                          title: l10n.myFavorites,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildSideButton(
                  focusNode: _settingsBtnFocusNode,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(child: const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCard({
    required FocusNode focusNode,
    required Widget graphic,
    required String titleText,
    required String counterText,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    bool isHovered = false;

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.select) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: StatefulBuilder(
        builder: (context, setState) {
          final isFocused = Focus.of(context).hasFocus;
          final active = isFocused || isHovered;

          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: const Cubic(0.2, 0.0, 0.0, 1.0),
                transform: active
                    ? Matrix4.translationValues(0.0, -3.0, 0.0)
                    : Matrix4.identity(),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1B1A32),
                      Color(0xFF16152A),
                    ],
                  ),
                  border: Border.all(
                    color: active ? const Color(0xFF6366F1) : const Color(0xFF2C2A4C),
                    width: active ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: active
                          ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: active ? 25 : 12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Center Graphic
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: graphic,
                    ),

                    // Title Row with optional Live pill badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (badgeText != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        Text(
                          titleText,
                          style: TextStyle(
                            color: active ? const Color(0xFFC7D2FE) : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Subtext / Counter
                    Text(
                      counterText,
                      style: const TextStyle(
                        color: Color(0xFF8F92A9),
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSideButton({
    required FocusNode focusNode,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isFavoritesIcon = false,
  }) {
    bool isHovered = false;

    return Expanded(
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.numpadEnter ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.select) {
              onTap();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            final isFocused = Focus.of(context).hasFocus;
            final active = isFocused || isHovered;

            return MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                  transform: active
                      ? Matrix4.translationValues(4.0, 0.0, 0.0)
                      : Matrix4.identity(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF2B294D) : const Color(0xFF1B1A32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active ? const Color(0xFF4F46E5) : const Color(0xFF2B294D),
                      width: active ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? const Color(0xFF4F46E5).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(right: 16),
                        child: isFavoritesIcon
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.crop_16_9,
                                    size: 32,
                                    color: active ? const Color(0xFFA5B4FC) : const Color(0xFF818CF8),
                                  ),
                                  Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: active ? const Color(0xFFA5B4FC) : const Color(0xFF818CF8),
                                  ),
                                ],
                              )
                            : Icon(
                                icon,
                                size: 30,
                                color: active ? const Color(0xFFA5B4FC) : const Color(0xFF818CF8),
                              ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final playlistName = _activePlaylist?.name ?? 'Demo';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF8F92A9), fontSize: 12, fontWeight: FontWeight.w500),
                children: [
                  const TextSpan(text: 'Current Playlist : '),
                  TextSpan(
                    text: playlistName,
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: const TextSpan(
                style: TextStyle(color: Color(0xFF8F92A9), fontSize: 12, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: 'Current playlist expires : '),
                  TextSpan(
                    text: 'Unlimited',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showExitDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1A32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2C2A4C)),
        ),
        title: Text(l10n.exit, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.confirmExit,
          style: const TextStyle(color: Color(0xFF8F92A9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF8F92A9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: Text(l10n.exit),
          ),
        ],
      ),
    );
  }
}
