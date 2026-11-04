import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/channel.dart';
import '../../models/playlist.dart';
import '../../services/database_service.dart';
import '../../services/preferences_service.dart';
import '../../services/vortextube_service.dart';
import '../../services/playlist_importer_service.dart';
import '../playlist_manager_screen.dart';

enum VortexSettingsTab {
  addToVortexTube,
  playlistsManager,
  epgGuide,
  aboutVortexTube,
}

enum VortexSettingsCategoryGroup {
  liveTv,
  vod,
  series,
}

class VortexSettingsView extends StatefulWidget {
  final VoidCallback onBackToSidebar;
  final VoidCallback onDataChanged;

  const VortexSettingsView({
    super.key,
    required this.onBackToSidebar,
    required this.onDataChanged,
  });

  @override
  State<VortexSettingsView> createState() => _VortexSettingsViewState();
}

class _VortexSettingsViewState extends State<VortexSettingsView> {
  VortexSettingsTab _activeTab = VortexSettingsTab.addToVortexTube;
  VortexSettingsCategoryGroup _activeCatGroup = VortexSettingsCategoryGroup.liveTv;

  // D-pad Navigation state within Settings: 'left' categories vs 'right' content
  bool _isRightPaneFocused = false;
  int _focusedLeftIndex = 0;
  int _focusedRightIndex = 0;

  // Real Data
  List<Playlist> _playlists = [];
  Playlist? _activePlaylist;
  Set<String> _favoriteCategories = {};
  Map<String, int> _liveCategories = {};
  Map<String, int> _movieCategories = {};
  Map<String, int> _seriesCategories = {};
  bool _isLoading = true;

  final ScrollController _rightScrollController = ScrollController();
  final FocusNode _settingsFocusNode = FocusNode();

  final List<Map<String, dynamic>> _tabs = [
    {
      'tab': VortexSettingsTab.addToVortexTube,
      'title': 'Add to VortexTube',
      'subtitle': 'Pins, favorites & shelf feeds',
      'icon': Icons.favorite_border_rounded,
    },
    {
      'tab': VortexSettingsTab.playlistsManager,
      'title': 'Playlists Manager',
      'subtitle': 'Active accounts & source switches',
      'icon': Icons.playlist_play_rounded,
    },
    {
      'tab': VortexSettingsTab.epgGuide,
      'title': 'EPG & TV Guide',
      'subtitle': 'XMLTV sync, timezone & catchup',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'tab': VortexSettingsTab.aboutVortexTube,
      'title': 'About VortexTube',
      'subtitle': 'Developer & App updates',
      'icon': Icons.info_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  @override
  void dispose() {
    _rightScrollController.dispose();
    _settingsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsData() async {
    setState(() => _isLoading = true);

    try {
      final playlists = await DatabaseService.getAllPlaylists();
      final activeId = await PreferencesService.getActivePlaylistId();
      Playlist? active;
      if (activeId != null) {
        active = await DatabaseService.getPlaylistById(activeId);
      }
      active ??= playlists.firstOrNull;

      final favCats = await PreferencesService.getFavoriteCategories();
      _favoriteCategories = favCats.toSet();

      final allChannels = await DatabaseService.getAllChannels();
      final Map<String, int> live = {};
      final Map<String, int> movies = {};
      final Map<String, int> series = {};

      for (final c in allChannels) {
        final grp = c.group;
        if (grp == null || grp.trim().isEmpty) continue;
        switch (c.contentType) {
          case ContentType.live:
            live[grp] = (live[grp] ?? 0) + 1;
            break;
          case ContentType.movie:
            movies[grp] = (movies[grp] ?? 0) + 1;
            break;
          case ContentType.series:
            series[grp] = (series[grp] ?? 0) + 1;
            break;
        }
      }

      if (mounted) {
        setState(() {
          _playlists = playlists;
          _activePlaylist = active;
          _liveCategories = live;
          _movieCategories = movies;
          _seriesCategories = series;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite(String category) async {
    final isFav = _favoriteCategories.contains(category);
    await PreferencesService.toggleFavoriteCategory(category);
    setState(() {
      if (isFav) {
        _favoriteCategories.remove(category);
      } else {
        _favoriteCategories.add(category);
      }
    });
    VortexTubeService.invalidateCache();
    widget.onDataChanged();
  }

  Future<void> _resetAllFavoriteCategories() async {
    final allFavs = List<String>.from(_favoriteCategories);
    for (final cat in allFavs) {
      await PreferencesService.toggleFavoriteCategory(cat);
    }
    setState(() {
      _favoriteCategories.clear();
    });
    VortexTubeService.invalidateCache();
    widget.onDataChanged();
  }

  Future<void> _setActivePlaylist(Playlist playlist) async {
    await PreferencesService.setActivePlaylistId(playlist.id);
    VortexTubeService.invalidateCache();
    await _loadSettingsData();
    widget.onDataChanged();
  }

  Future<void> _showAddPlaylistDialog() async {
    final result = await showDialog<Playlist>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PlaylistDialog(),
    );

    if (result != null && mounted) {
      final importResult = await PlaylistImporterService.importPlaylist(context, result);
      if (mounted) {
        if (importResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added playlist "${result.name}" with ${importResult["count"]} items'),
              backgroundColor: const Color(0xFF1B6B38),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to import playlist: ${importResult["error"]}'),
              backgroundColor: const Color(0xFFB3261E),
            ),
          );
        }
        await _loadSettingsData();
        widget.onDataChanged();
      }
    }
  }

  Future<void> _showEditPlaylistDialog(Playlist playlist) async {
    final result = await showDialog<Playlist>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlaylistDialog(playlist: playlist),
    );

    if (result != null && mounted) {
      final importResult = await PlaylistImporterService.importPlaylist(context, result, isEdit: true);
      if (mounted) {
        if (importResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated playlist "${result.name}"'),
              backgroundColor: const Color(0xFF1B6B38),
            ),
          );
        }
        await _loadSettingsData();
        widget.onDataChanged();
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      if (_isRightPaneFocused) {
        setState(() => _isRightPaneFocused = false);
      } else {
        widget.onBackToSidebar();
      }
      return;
    }

    if (!_isRightPaneFocused) {
      // Left Categories navigation
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _focusedLeftIndex = (_focusedLeftIndex + 1) % _tabs.length;
          _activeTab = _tabs[_focusedLeftIndex]['tab'] as VortexSettingsTab;
        });
      } else if (key == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _focusedLeftIndex = (_focusedLeftIndex - 1 + _tabs.length) % _tabs.length;
          _activeTab = _tabs[_focusedLeftIndex]['tab'] as VortexSettingsTab;
        });
      } else if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select) {
        setState(() {
          _isRightPaneFocused = true;
          _focusedRightIndex = 0;
        });
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        widget.onBackToSidebar();
      }
    } else {
      // Right pane navigation
      if (key == LogicalKeyboardKey.arrowLeft) {
        setState(() => _isRightPaneFocused = false);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        setState(() => _focusedRightIndex++);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        if (_focusedRightIndex > 0) {
          setState(() => _focusedRightIndex--);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _settingsFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: const Color(0xFF0B0B0E),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Categories D-Pad list
                  SizedBox(
                    width: 310,
                    child: _buildLeftCategoryList(),
                  ),
                  const SizedBox(width: 24),
                  // Right Detail Viewport
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121216),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF22222A)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: Color(0xFFFF0000), strokeWidth: 2.5),
                            )
                          : _buildActivePanel(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildFooterLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F1F26), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (_activePlaylist != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E2E3A)),
              ),
              child: Text(
                'Active: ${_activePlaylist!.name}',
                style: const TextStyle(color: Color(0xFFA0A0AD), fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftCategoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORIES',
                style: TextStyle(
                  color: Color(0xFF727282),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'D-PAD ▲ ▼',
                style: TextStyle(color: Color(0xFF555562), fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _tabs[index];
            final tab = item['tab'] as VortexSettingsTab;
            final isActive = _activeTab == tab;
            final isFocused = !_isRightPaneFocused && _focusedLeftIndex == index;

            Color bgColor;
            Color textColor;
            Color subColor;
            Color iconColor;

            if (isActive) {
              bgColor = Colors.white;
              textColor = Colors.black;
              subColor = const Color(0xFF444444);
              iconColor = Colors.black;
            } else {
              bgColor = const Color(0xFF141418);
              textColor = const Color(0xFFE5E5E5);
              subColor = const Color(0xFF7A7A88);
              iconColor = const Color(0xFF8D8D9B);
            }

            return InkWell(
              onTap: () {
                setState(() {
                  _activeTab = tab;
                  _focusedLeftIndex = index;
                  _isRightPaneFocused = false;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused ? Colors.white : (isActive ? Colors.white : const Color(0xFF23232B)),
                    width: isFocused ? 2.5 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: iconColor, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: TextStyle(
                              color: subColor,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '>',
                      style: TextStyle(
                        color: isActive ? Colors.black : const Color(0xFF555562),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivePanel() {
    switch (_activeTab) {
      case VortexSettingsTab.addToVortexTube:
        return _buildAddToVortexTubePanel();
      case VortexSettingsTab.playlistsManager:
        return _buildPlaylistsManagerPanel();
      case VortexSettingsTab.epgGuide:
        return _buildEpgGuidePanel();
      case VortexSettingsTab.aboutVortexTube:
        return _buildAboutVortexTubePanel();
    }
  }

  Widget _buildAddToVortexTubePanel() {
    Map<String, int> activeCats;
    IconData defaultIcon;

    switch (_activeCatGroup) {
      case VortexSettingsCategoryGroup.liveTv:
        activeCats = _liveCategories;
        defaultIcon = Icons.live_tv_rounded;
        break;
      case VortexSettingsCategoryGroup.vod:
        activeCats = _movieCategories;
        defaultIcon = Icons.movie_outlined;
        break;
      case VortexSettingsCategoryGroup.series:
        activeCats = _seriesCategories;
        defaultIcon = Icons.video_collection_outlined;
        break;
    }

    final sortedCatEntries = activeCats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Add to VortexTube',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Select and favorite categories to display on your VortexTube player home shelves',
                  style: TextStyle(color: Color(0xFF828290), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        // 3-Type Segmented Category Selector Tabs (Live TV, Movies / VOD, Series)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF17171E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF252532)),
          ),
          child: Row(
            children: [
              _buildTypeTab('Live TV', Icons.live_tv_rounded, VortexSettingsCategoryGroup.liveTv),
              _buildTypeTab('Movies / VOD', Icons.movie_outlined, VortexSettingsCategoryGroup.vod),
              _buildTypeTab('Series', Icons.video_collection_outlined, VortexSettingsCategoryGroup.series),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Subheader
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _activeCatGroup == VortexSettingsCategoryGroup.liveTv
                  ? 'LIVE TV FEEDS & CHANNELS'
                  : _activeCatGroup == VortexSettingsCategoryGroup.vod
                      ? 'MOVIES & ON-DEMAND'
                      : 'TV SERIES & BOX SETS',
              style: const TextStyle(
                color: Color(0xFF737380),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const Text(
              'Press OK to pin/unpin shelf',
              style: TextStyle(color: Color(0xFF888894), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Grid of Category Cards (2 columns)
        Expanded(
          child: sortedCatEntries.isEmpty
              ? const Center(
                  child: Text(
                    'No categories found in active playlist.',
                    style: TextStyle(color: Color(0xFF888894), fontSize: 13),
                  ),
                )
              : GridView.builder(
                  controller: _rightScrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.8,
                  ),
                  itemCount: sortedCatEntries.length,
                  itemBuilder: (context, idx) {
                    final entry = sortedCatEntries[idx];
                    final catName = entry.key;
                    final count = entry.value;
                    final isSelected = _favoriteCategories.contains(catName);

                    return InkWell(
                      onTap: () => _toggleFavorite(catName),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17171D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4A4A5A) : const Color(0xFF242430),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF33333D) : const Color(0xFF21212A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF4A4A4A) : const Color(0xFF2C2C38),
                                ),
                              ),
                              child: Icon(
                                defaultIcon,
                                color: isSelected ? Colors.white : const Color(0xFF8D8D9B),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    catName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$count items',
                                    style: const TextStyle(color: Color(0xFF8D8D9B), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFF4A4A4A) : Colors.transparent,
                                border: isSelected ? null : Border.all(color: const Color(0xFF3B3B4A)),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 15)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF202028), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Color(0xFF828290), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Pinned shelves update automatically on VortexTube player home',
                    style: TextStyle(color: Color(0xFF828290), fontSize: 11.5),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _resetAllFavoriteCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20202A),
                  foregroundColor: const Color(0xFFCCCCCC),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF2C2C38)),
                  ),
                ),
                child: const Text('Reset All Shelves', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTab(String title, IconData icon, VortexSettingsCategoryGroup group) {
    final isSelected = _activeCatGroup == group;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeCatGroup = group;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.black : const Color(0xFF8D8D9B)),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFF8D8D9B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsManagerPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Playlists Manager',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Switch default IPTV provider, re-index categories or manage login streams',
                  style: TextStyle(color: Color(0xFF828290), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Add New Playlist Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _showAddPlaylistDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add New Playlist / Portal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ACTIVE PLAYLISTS',
          style: TextStyle(
            color: Color(0xFF737380),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            controller: _rightScrollController,
            itemCount: _playlists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final pl = _playlists[idx];
              final isActive = _activePlaylist?.id == pl.id;

              return InkWell(
                onTap: () => _setActivePlaylist(pl),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1A1A22) : const Color(0xFF17171D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.white70 : const Color(0xFF252530),
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF21212A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          pl.sourceType == PlaylistSourceType.stalker
                              ? Icons.settings_input_antenna_rounded
                              : Icons.playlist_play_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pl.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A35),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    pl.sourceType.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFCCCCCC),
                                      fontSize: 9.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pl.sourceType == PlaylistSourceType.stalker
                                  ? 'Stalker Portal • MAC: ${pl.macAddress ?? "Default"}'
                                  : (pl.url.length > 45 ? '${pl.url.substring(0, 45)}...' : pl.url),
                              style: const TextStyle(color: Color(0xFF828292), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditPlaylistDialog(pl),
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                        tooltip: 'Edit Playlist',
                      ),
                      const SizedBox(width: 8),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check, color: Colors.black, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEpgGuidePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'EPG & TV Guide',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Program guide synchronization, timezone offsets, and XMLTV source URLs',
                  style: TextStyle(color: Color(0xFF828290), fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF06331C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0F6838)),
              ),
              child: const Text(
                'Status: Synced',
                style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF17171D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF262633)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Time Shift Offset', style: TextStyle(color: Color(0xFF8D8D9B), fontSize: 11)),
                    SizedBox(height: 6),
                    Text('UTC +00:00 (Auto)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF17171D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF262633)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Auto-Update Frequency', style: TextStyle(color: Color(0xFF8D8D9B), fontSize: 11)),
                    SizedBox(height: 6),
                    Text('Every 6 Hours', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'EPG TIMELINE CACHE',
          style: TextStyle(
            color: Color(0xFF737380),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16161D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF262633)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Timeline Cache: 48 Hours', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  Text('EPG Data Active', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.85,
                  minHeight: 6,
                  backgroundColor: Color(0xFF20202A),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutVortexTubePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'About VortexTube',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Your TV Friendly Player for better user experience and better personalization.',
                  style: TextStyle(color: Color(0xFF828290), fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1015),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF661520)),
              ),
              child: const Text(
                'Developed By CK',
                style: TextStyle(color: Color(0xFFFFA0AA), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF16161D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF262633)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0033).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.system_update_rounded, color: Color(0xFFFF0033), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'App Updates',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Directly update when new version is available',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('VortexTube is up to date!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4A4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Check for Updates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLegend() {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1C1C24), width: 1)),
      ),
      child: Row(
        children: [
          _buildLegendKey('▲ / ▼', 'Navigate Items'),
          const SizedBox(width: 20),
          _buildLegendKey('◄ / ►', 'Switch Panes'),
          const SizedBox(width: 20),
          _buildLegendKey('OK / ENTER', 'Select / Toggle'),
          const SizedBox(width: 20),
          _buildLegendKey('BACK / ESC', 'Return to Sidebar'),
        ],
      ),
    );
  }

  Widget _buildLegendKey(String key, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A22),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2E2E3A)),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF828292), fontSize: 11),
        ),
      ],
    );
  }
}
