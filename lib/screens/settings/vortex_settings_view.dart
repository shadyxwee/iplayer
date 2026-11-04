import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/channel.dart';
import '../../models/playlist.dart';
import '../../services/database_service.dart';
import '../../services/preferences_service.dart';
import '../../services/vortextube_service.dart';
import '../../services/playlist_importer_service.dart';

enum VortexSettingsTab {
  addToVortexTube,
  playlistsManager,
  addPortal,
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

  // Add / Edit Portal Form State
  Playlist? _editingPlaylist;
  PlaylistSourceType _portalSourceType = PlaylistSourceType.xtreamCodes;
  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    _playlistNameController.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
    if (mounted) {
      setState(() {
        if (isFav) {
          _favoriteCategories.remove(category);
        } else {
          _favoriteCategories.add(category);
        }
      });
    }
    VortexTubeService.invalidateCache();
  }

  Future<void> _resetAllFavoriteCategories() async {
    final allFavs = List<String>.from(_favoriteCategories);
    for (final cat in allFavs) {
      await PreferencesService.toggleFavoriteCategory(cat);
    }
    if (mounted) {
      setState(() {
        _favoriteCategories.clear();
      });
    }
    VortexTubeService.invalidateCache();
  }

  Future<void> _setActivePlaylist(Playlist playlist) async {
    await PreferencesService.setActivePlaylistId(playlist.id);
    VortexTubeService.invalidateCache();
    await _loadSettingsData();
    widget.onDataChanged();
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${playlist.name}" and all its content?',
          style: const TextStyle(color: Color(0xFFCCCCCC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await DatabaseService.deletePlaylist(playlist.id);
      final remaining = await DatabaseService.getAllPlaylists();
      final activeId = await PreferencesService.getActivePlaylistId();
      if (activeId == playlist.id) {
        if (remaining.isNotEmpty) {
          await PreferencesService.setActivePlaylistId(remaining.first.id);
        } else {
          await PreferencesService.setActivePlaylistId(null);
        }
      }
      if (remaining.isEmpty) {
        final allFavs = await PreferencesService.getFavoriteCategories();
        for (final fav in allFavs) {
          await PreferencesService.toggleFavoriteCategory(fav);
        }
        _favoriteCategories.clear();
      }
      VortexTubeService.invalidateCache();
      await _loadSettingsData();
      widget.onDataChanged();
    }
  }

  void _openAddPortalForm() {
    setState(() {
      _editingPlaylist = null;
      _portalSourceType = PlaylistSourceType.xtreamCodes;
      _playlistNameController.clear();
      _serverUrlController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _activeTab = VortexSettingsTab.addPortal;
      _isRightPaneFocused = true;
      _focusedRightIndex = 0;
    });
  }

  void _openEditPortalForm(Playlist playlist) {
    setState(() {
      _editingPlaylist = playlist;
      _portalSourceType = playlist.sourceType;
      _playlistNameController.text = playlist.name;
      _serverUrlController.text = playlist.url;
      _usernameController.text = playlist.sourceType == PlaylistSourceType.stalker
          ? (playlist.macAddress ?? '')
          : (playlist.username ?? '');
      _passwordController.text = playlist.password ?? '';
      _activeTab = VortexSettingsTab.addPortal;
      _isRightPaneFocused = true;
      _focusedRightIndex = 0;
    });
  }

  Future<void> _submitPortalForm() async {
    final name = _playlistNameController.text.trim();
    final url = _serverUrlController.text.trim();
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Playlist Name and URL'),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
      return;
    }

    final isEdit = _editingPlaylist != null;
    final playlist = _editingPlaylist ?? Playlist();
    playlist.name = name;
    playlist.url = url;
    playlist.sourceType = _portalSourceType;

    if (_portalSourceType == PlaylistSourceType.stalker) {
      playlist.macAddress = user;
      playlist.username = null;
      playlist.password = null;
    } else if (_portalSourceType == PlaylistSourceType.xtreamCodes) {
      playlist.username = user;
      playlist.password = pass;
      playlist.macAddress = null;
    } else {
      playlist.username = null;
      playlist.password = null;
      playlist.macAddress = null;
    }

    final importResult = await PlaylistImporterService.importPlaylist(
      context,
      playlist,
      isEdit: isEdit,
    );

    if (mounted) {
      if (importResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Updated playlist "$name"'
                : 'Added playlist "$name" with ${importResult["count"]} items'),
            backgroundColor: const Color(0xFF1B6B38),
          ),
        );
        setState(() {
          _activeTab = VortexSettingsTab.playlistsManager;
          _isRightPaneFocused = false;
        });
        await _loadSettingsData();
        widget.onDataChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${importResult["error"]}'),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      if (_activeTab == VortexSettingsTab.addPortal) {
        setState(() {
          _activeTab = VortexSettingsTab.playlistsManager;
          _isRightPaneFocused = false;
        });
        return;
      }
      if (_isRightPaneFocused) {
        setState(() => _isRightPaneFocused = false);
      } else {
        widget.onBackToSidebar();
      }
      return;
    }

    if (!_isRightPaneFocused) {
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
                  SizedBox(
                    width: 310,
                    child: _buildLeftCategoryList(),
                  ),
                  const SizedBox(width: 24),
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
            final isPlaylistsTab = tab == VortexSettingsTab.playlistsManager;
            final isActive = _activeTab == tab || (_activeTab == VortexSettingsTab.addPortal && isPlaylistsTab);
            final isFocused = !_isRightPaneFocused && _focusedLeftIndex == index;

            Color bgColor = isActive ? Colors.white : const Color(0xFF141418);
            Color textColor = isActive ? Colors.black : const Color(0xFFE5E5E5);
            Color subColor = isActive ? const Color(0xFF444444) : const Color(0xFF7A7A88);
            Color iconColor = isActive ? Colors.black : const Color(0xFF8D8D9B);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
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
                ),
                // Nested breadcrumb for Add / Edit Portal
                if (isPlaylistsTab && _activeTab == VortexSettingsTab.addPortal) ...[
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C24),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(left: BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('↳ ', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                            Text(
                              _editingPlaylist != null ? 'Edit: ${_editingPlaylist!.name}' : 'Add New Portal',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2E38),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('WIZARD', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
      case VortexSettingsTab.addPortal:
        return _buildAddPortalPanel();
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to VortexTube',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Select and favorite categories across Live TV, Movies / VOD, and Series to display on your VortexTube player home shelves',
                  style: TextStyle(color: Color(0xFF828290), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
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
        Expanded(
          child: sortedCatEntries.isEmpty
              ? const Center(
                  child: Text(
                    'No categories found in active playlist.',
                    style: TextStyle(color: Color(0xFF888894), fontSize: 13),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final int cols = constraints.maxWidth > 900 ? 4 : 3;
                    return GridView.builder(
                      key: ValueKey('grid_${_activeCatGroup.name}'),
                      controller: _rightScrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.8,
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                  width: 28,
                                  height: 28,
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
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        catName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '$count items',
                                        style: const TextStyle(color: Color(0xFF8D8D9B), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? const Color(0xFF4A4A4A) : Colors.transparent,
                                    border: isSelected ? null : Border.all(color: const Color(0xFF3B3B4A)),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
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
          children: const [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openAddPortalForm,
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
                        onPressed: () => _openEditPortalForm(pl),
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                        tooltip: 'Edit Playlist',
                      ),
                      IconButton(
                        onPressed: () => _deletePlaylist(pl),
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4444), size: 18),
                        tooltip: 'Delete Playlist',
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

  Widget _buildAddPortalPanel() {
    final isEdit = _editingPlaylist != null;

    return SingleChildScrollView(
      controller: _rightScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _activeTab = VortexSettingsTab.playlistsManager),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2C2C38)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Playlist / Portal' : 'Add New Playlist / Portal',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Connect Xtream Codes API, M3U file/URL, or configure MAC address portal',
                    style: TextStyle(color: Color(0xFF828290), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Protocol Selector Buttons Radio Group
          Row(
            children: [
              _buildPortalTypeRadio('Xtream Codes', PlaylistSourceType.xtreamCodes),
              const SizedBox(width: 12),
              _buildPortalTypeRadio('M3U URL / File', PlaylistSourceType.m3u),
              const SizedBox(width: 12),
              _buildPortalTypeRadio('Stalker MAC', PlaylistSourceType.stalker),
            ],
          ),
          const SizedBox(height: 20),
          // Form inputs matching HTML/Tailwind spec
          _buildFormLabel('PLAYLIST NAME'),
          _buildFormInput(_playlistNameController, 'e.g. My IPTV Provider'),
          const SizedBox(height: 14),
          _buildFormLabel(_portalSourceType == PlaylistSourceType.stalker
              ? 'PORTAL URL'
              : (_portalSourceType == PlaylistSourceType.m3u
                  ? 'M3U PLAYLIST URL OR LOCAL PATH'
                  : 'SERVER URL / PORTAL DOMAIN')),
          _buildFormInput(
            _serverUrlController,
            _portalSourceType == PlaylistSourceType.stalker ? 'http://stalker-server.net/c/' : 'http://domain.com:port',
            isMono: true,
          ),
          const SizedBox(height: 14),
          if (_portalSourceType != PlaylistSourceType.m3u) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel(_portalSourceType == PlaylistSourceType.stalker ? 'MAC ADDRESS' : 'USERNAME'),
                      _buildFormInput(
                        _usernameController,
                        _portalSourceType == PlaylistSourceType.stalker ? '00:1A:79:XX:XX:XX' : 'Enter username',
                        isMono: _portalSourceType == PlaylistSourceType.stalker,
                      ),
                    ],
                  ),
                ),
                if (_portalSourceType == PlaylistSourceType.xtreamCodes) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('PASSWORD / PIN'),
                        _buildFormInput(_passwordController, 'Enter password or PIN', isPassword: true),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              ElevatedButton(
                onPressed: _submitPortalForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4A4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() => _activeTab = VortexSettingsTab.playlistsManager),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCCCCCC),
                  side: const BorderSide(color: Color(0xFF33333F)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortalTypeRadio(String label, PlaylistSourceType type) {
    final isSelected = _portalSourceType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _portalSourceType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFF17171D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : const Color(0xFF282834),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFFCCCCCC),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9E9EA8),
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFormInput(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool isMono = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181820),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C3A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontFamily: isMono ? 'monospace' : null,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF666672), fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
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
