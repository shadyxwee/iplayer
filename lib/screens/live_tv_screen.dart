import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../services/m3u_parser.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'epg_screen.dart';

class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({Key? key}) : super(key: key);

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  Map<String, Map<String, List<Channel>>> _hierarchy = {};
  String? _selectedParentCategory;
  String? _selectedSubCategory;
  String _searchQuery = '';
  Channel? _selectedChannel;

  // Video player
  Player? player;
  VideoController? controller;
  bool _isPlayerInitialized = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    final allChannels = await DatabaseService.getAllChannels();
    final liveChannels = allChannels
        .where((c) => c.contentType == ContentType.live)
        .toList();

    final hierarchy = M3UParser.groupChannelsHierarchical(liveChannels);

    setState(() {
      _allChannels = liveChannels;
      _filteredChannels = liveChannels;
      _hierarchy = hierarchy;

      // Auto-select first channel
      if (liveChannels.isNotEmpty) {
        _playChannel(liveChannels.first);
      }
    });
  }

  void _filterChannels() {
    List<Channel> filtered = _allChannels;

    if (_selectedParentCategory != null) {
      if (_selectedSubCategory != null && _selectedSubCategory != 'All') {
        filtered = filtered.where((c) {
          final g = (c.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          final sub = _selectedSubCategory!.toLowerCase();
          return g.contains(p) && g.contains(sub);
        }).toList();
      } else {
        filtered = filtered.where((c) {
          final g = (c.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          return g.startsWith(p) || g == p;
        }).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredChannels = filtered;
    });
  }

  Future<void> _playChannel(Channel channel) async {
    // Dispose old player
    await player?.dispose();

    // Create new player
    final newPlayer = Player();
    final newController = VideoController(newPlayer);

    setState(() {
      _selectedChannel = channel;
      player = newPlayer;
      controller = newController;
      _isPlayerInitialized = false;
    });

    try {
      await newPlayer.open(Media(channel.url));
      await DatabaseService.updateChannelPlayCount(channel);
      setState(() {
        _isPlayerInitialized = true;
      });
    } catch (e) {
      print('Error playing channel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: theme.backgroundPrimary,
          body: Row(
            children: [
              // Left Sidebar - Categories
              if (!_isFullscreen)
                Container(
              width: 220,
              decoration: BoxDecoration(
                color: theme.sidebarBackground,
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.textPrimary, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'IPTV',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.liveTV,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    style: TextStyle(color: theme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: theme.textSecondary.withOpacity(0.5), size: 18),
                      filled: true,
                      fillColor: theme.backgroundTertiary,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterChannels();
                    },
                  ),
                ),

                // Categories list
                Expanded(
                  child: ListView.builder(
                    itemCount: _hierarchy.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedParentCategory == null;
                        return _buildCategoryItem(l10n.all, isSelected, () {
                          setState(() {
                            _selectedParentCategory = null;
                            _selectedSubCategory = null;
                          });
                          _filterChannels();
                        }, theme);
                      }

                      final parent = _hierarchy.keys.elementAt(index - 1);
                      final subs = _hierarchy[parent]!;
                      final isParentSelected = _selectedParentCategory == parent;

                      return Column(
                        children: [
                          _buildCategoryItem(parent, isParentSelected, () {
                            setState(() {
                              if (_selectedParentCategory == parent && _selectedSubCategory == 'All') {
                                _selectedParentCategory = null;
                                _selectedSubCategory = null;
                              } else {
                                _selectedParentCategory = parent;
                                _selectedSubCategory = 'All';
                              }
                            });
                            _filterChannels();
                          }, theme, hasSub: subs.length > 1),
                          
                          if (isParentSelected && subs.length > 1)
                            ...subs.keys.map((sub) {
                              final isSubSelected = _selectedSubCategory == sub;
                              return Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: _buildCategoryItem(sub, isSubSelected, () {
                                  setState(() {
                                    _selectedSubCategory = sub;
                                  });
                                  _filterChannels();
                                }, theme, isSub: true),
                              );
                            }).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
                ),

              // Middle - Channel list
              if (!_isFullscreen)
                Container(
              width: 380,
            decoration: BoxDecoration(
              color: theme.backgroundTertiary,
              border: Border(
                right: BorderSide(
                  color: theme.borderPrimary.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Top bar with search
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.sidebarBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.borderPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            style: TextStyle(color: theme.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: l10n.search,
                              hintStyle: TextStyle(
                                color: theme.textSecondary.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: theme.textSecondary.withOpacity(0.5),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _filterChannels();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Categories
                      IconButton(
                        tooltip: l10n.categories,
                        icon: Icon(Icons.grid_view_rounded, color: theme.textPrimary, size: 20),
                        onPressed: () {
                          // Show categories bottom sheet or similar
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
                        },
                      ),
                      // EPG Guide
                      IconButton(
                        tooltip: l10n.epgGuide,
                        icon: Icon(Icons.calendar_month_rounded, color: theme.textPrimary, size: 20),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EpgScreen()));
                        },
                      ),
                      // Switch to Movies
                      IconButton(
                        tooltip: l10n.movies,
                        icon: Icon(Icons.play_circle_outline_rounded, color: theme.textPrimary, size: 20),
                        onPressed: () {
                          Navigator.pop(context); // Go back to dashboard and user can click movies
                        },
                      ),
                      // Refresh
                      IconButton(
                        tooltip: l10n.refresh,
                        icon: const Icon(Icons.replay_rounded, color: Color(0xFF5DD3E5), size: 20),
                        onPressed: () {
                          _loadChannels();
                        },
                      ),
                    ],
                  ),
                ),

                // Channel list
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredChannels.length,
                    itemBuilder: (context, index) {
                      final channel = _filteredChannels[index];
                      final isSelected = _selectedChannel?.id == channel.id;

                      return Material(
                        color: isSelected
                            ? theme.cardBackgroundLight
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => _playChannel(channel),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // Channel number
                                Container(
                                  width: 35,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.accentPrimary
                                        : theme.sidebarBackground,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected ? null : Border.all(color: theme.borderPrimary.withOpacity(0.1)),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : theme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Channel logo
                                if (channel.logo != null)
                                  Container(
                                    width: 35,
                                    height: 35,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: theme.textPrimary.withOpacity(0.1),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        channel.logo!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.tv,
                                            color: theme.textSecondary.withOpacity(0.3),
                                            size: 18,
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                // Channel name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        channel.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? theme.accentPrimary
                                              : theme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (channel.group != null)
                                        Text(
                                          channel.group!,
                                          style: TextStyle(
                                            color: theme.textSecondary.withOpacity(0.5),
                                            fontSize: 10,
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
                      );
                    },
                  ),
                ),
              ],
            ),
                ),

              // Right side - Video Player
              Expanded(
            child: Container(
              color: Colors.black,
              child: _selectedChannel == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tv,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.selectChannel,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Channel info bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_selectedChannel!.logo != null)
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Image.network(
                                    _selectedChannel!.logo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.tv,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedChannel!.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_selectedChannel!.group != null)
                                      Text(
                                        _selectedChannel!.group!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Volume control
                              if (player != null)
                                StreamBuilder<double>(
                                  stream: player!.stream.volume,
                                  builder: (context, snapshot) {
                                    final volume = snapshot.data ?? 100.0;
                                    final isMuted = volume == 0.0;

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isMuted
                                                ? Icons.volume_off
                                                : volume < 50
                                                    ? Icons.volume_down
                                                    : Icons.volume_up,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            if (isMuted) {
                                              player!.setVolume(100);
                                            } else {
                                              player!.setVolume(0);
                                            }
                                          },
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: SliderTheme(
                                            data: SliderThemeData(
                                              trackHeight: 2,
                                              thumbShape: const RoundSliderThumbShape(
                                                enabledThumbRadius: 4,
                                              ),
                                              overlayShape: const RoundSliderOverlayShape(
                                                overlayRadius: 8,
                                              ),
                                            ),
                                            child: Slider(
                                              value: volume.clamp(0.0, 100.0),
                                              min: 0,
                                              max: 100,
                                              onChanged: (value) {
                                                player!.setVolume(value);
                                              },
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.white.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  _selectedChannel!.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _selectedChannel!.isFavorite
                                      ? Colors.red
                                      : Colors.white,
                                ),
                                onPressed: () async {
                                  await DatabaseService.toggleFavorite(_selectedChannel!);
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isFullscreen = !_isFullscreen;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // Video player
                        Expanded(
                          child: controller != null && _isPlayerInitialized
                              ? Video(
                                  controller: controller!,
                                  controls: NoVideoControls,
                                )
                              : Center(
                                  child: CircularProgressIndicator(
                                    color: theme.accentPrimary,
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, bool isSelected, VoidCallback onTap, AppThemeType theme, {bool hasSub = false, bool isSub = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSub ? 10 : 14,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? theme.accentPrimary : Colors.transparent,
                width: 3,
              ),
            ),
            color: isSelected ? theme.textPrimary.withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? theme.accentPrimary : theme.textPrimary.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSub ? 13 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSub)
                Icon(
                  isSelected ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: isSelected ? theme.accentPrimary : theme.textSecondary.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
