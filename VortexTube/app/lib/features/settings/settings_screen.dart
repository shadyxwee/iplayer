import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models.dart';
import '../../core/storage_service.dart';

enum SettingsCategory {
  addToVortexTube,
  playlistsManager,
  epgGuide,
  aboutVortexTube,
}

enum PortalType {
  xtream,
  m3u,
  stalker,
}

class TVSettingsScreen extends StatefulWidget {
  final int initialCategoryIndex;

  const TVSettingsScreen({super.key, this.initialCategoryIndex = 0});

  @override
  State<TVSettingsScreen> createState() => _TVSettingsScreenState();
}

class _TVSettingsScreenState extends State<TVSettingsScreen> {
  // Navigation State
  bool _isRightPaneFocused = false;
  int _selectedCategoryIndex = 0;
  int _rightPaneFocusIndex = 0;
  bool _isWizardOpen = false;

  // Add to VortexTube Sub-tabs (0: Live TV, 1: Movies / VOD, 2: Series)
  int _categoryGroupIndex = 0;

  // Data
  List<PlaylistModel> _playlists = [];
  Set<String> _favoriteCategories = {};
  bool _isLoading = true;

  // Wizard Form controllers
  PortalType _wizardPortalType = PortalType.xtream;
  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _macAddressController = TextEditingController();
  PlaylistModel? _editingPlaylist;

  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex.clamp(0, 3);
    _loadData();
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _playlistNameController.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _macAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final playlists = await StorageService.getPlaylists();
    final favs = await StorageService.getFavoriteCategories();
    if (mounted) {
      setState(() {
        _playlists = playlists;
        _favoriteCategories = favs;
        _isLoading = false;
      });
    }
  }

  void _openAddPortal() {
    setState(() {
      _isWizardOpen = true;
      _editingPlaylist = null;
      _wizardPortalType = PortalType.xtream;
      _playlistNameController.clear();
      _serverUrlController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _macAddressController.clear();
      _isRightPaneFocused = true;
      _rightPaneFocusIndex = 0;
    });
  }

  void _openEditPortal(PlaylistModel pl) {
    setState(() {
      _isWizardOpen = true;
      _editingPlaylist = pl;
      if (pl.isStalker) {
        _wizardPortalType = PortalType.stalker;
      } else if (pl.isM3u) {
        _wizardPortalType = PortalType.m3u;
      } else {
        _wizardPortalType = PortalType.xtream;
      }
      _playlistNameController.text = pl.name;
      _serverUrlController.text = pl.url;
      _usernameController.text = pl.username ?? '';
      _passwordController.text = pl.password ?? '';
      _macAddressController.text = pl.macAddress ?? '';
      _isRightPaneFocused = true;
      _rightPaneFocusIndex = 0;
    });
  }

  Future<void> _savePortal() async {
    final name = _playlistNameController.text.trim();
    final url = _serverUrlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in playlist name and server URL')),
      );
      return;
    }

    PlaylistSourceType sourceType;
    if (_wizardPortalType == PortalType.stalker) {
      sourceType = PlaylistSourceType.stalker;
    } else if (_wizardPortalType == PortalType.m3u) {
      sourceType = PlaylistSourceType.m3u;
    } else {
      sourceType = PlaylistSourceType.xtreamCodes;
    }

    if (_editingPlaylist != null) {
      final updated = PlaylistModel(
        id: _editingPlaylist!.id,
        name: name,
        sourceType: sourceType,
        url: url,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        macAddress: _macAddressController.text.trim(),
        isActive: _editingPlaylist!.isActive,
      );
      final idx = _playlists.indexWhere((p) => p.id == _editingPlaylist!.id);
      if (idx != -1) {
        _playlists[idx] = updated;
      }
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final newPl = PlaylistModel(
        id: newId,
        name: name,
        sourceType: sourceType,
        url: url,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        macAddress: _macAddressController.text.trim(),
        isActive: _playlists.isEmpty,
      );
      _playlists.add(newPl);
    }

    await StorageService.savePlaylists(_playlists);
    setState(() {
      _isWizardOpen = false;
      _rightPaneFocusIndex = 0;
    });
  }

  // Handle D-Pad Remote Navigation
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      if (!_isRightPaneFocused) {
        setState(() {
          _selectedCategoryIndex = (_selectedCategoryIndex + 1) % 4;
        });
      } else {
        setState(() {
          _rightPaneFocusIndex++;
        });
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (!_isRightPaneFocused) {
        setState(() {
          _selectedCategoryIndex = (_selectedCategoryIndex - 1 + 4) % 4;
        });
      } else {
        if (_rightPaneFocusIndex > 0) {
          setState(() {
            _rightPaneFocusIndex--;
          });
        }
      }
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (!_isRightPaneFocused) {
        setState(() {
          _isRightPaneFocused = true;
          _rightPaneFocusIndex = 0;
        });
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (_isRightPaneFocused) {
        setState(() {
          _isRightPaneFocused = false;
        });
      }
    } else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      if (_isWizardOpen) {
        setState(() {
          _isWizardOpen = false;
          _rightPaneFocusIndex = 0;
        });
      } else if (_isRightPaneFocused) {
        setState(() {
          _isRightPaneFocused = false;
        });
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Categories Navigation
                      SizedBox(
                        width: 340,
                        child: _buildLeftCategoriesNav(),
                      ),
                      const SizedBox(width: 32),
                      // Right Detail Viewport
                      Expanded(
                        child: _buildRightDetailPanel(),
                      ),
                    ],
                  ),
                ),
                _buildRemoteFooterLegend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
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
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
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
        ],
      ),
    );
  }

  Widget _buildLeftCategoriesNav() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
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
                style: TextStyle(color: Color(0xFF555555), fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _buildNavButton(0, 'Add to VortexTube', 'Pins, favorites & shelf feeds', Icons.favorite_rounded),
        const SizedBox(height: 10),
        _buildNavButton(1, 'Playlists Manager', 'Active accounts & source switches', Icons.playlist_play_rounded),
        if (_isWizardOpen && _selectedCategoryIndex == 1) ...[
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(8),
              border: const Border(left: BorderSide(color: Colors.white, width: 2.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingPlaylist != null ? 'Edit: ${_editingPlaylist!.name}' : 'Add New Portal',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF2E2E38), borderRadius: BorderRadius.circular(4)),
                  child: const Text('WIZARD', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildNavButton(2, 'EPG & TV Guide', 'XMLTV sync, timezone & catchup', Icons.calendar_month_rounded),
        const SizedBox(height: 10),
        _buildNavButton(3, 'About VortexTube', 'Developer & App updates', Icons.info_rounded),
      ],
    );
  }

  Widget _buildNavButton(int index, String title, String subtitle, IconData icon) {
    final isSelected = _selectedCategoryIndex == index;
    final isFocusedOnLeft = !_isRightPaneFocused && isSelected;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
          _isRightPaneFocused = false;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF141418),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocusedOnLeft
                ? Colors.white
                : (isSelected ? Colors.white : const Color(0xFF23232B)),
            width: isFocusedOnLeft ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.black : const Color(0xFF8D8D9B),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFFE4E4E7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF555555) : const Color(0xFF71717A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isSelected ? Colors.black : const Color(0xFF71717A),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightDetailPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121216),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRightPaneFocused ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF22222A),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(28),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF0000)))
          : (_isWizardOpen
              ? _buildWizardPanel()
              : (_selectedCategoryIndex == 0
                  ? _buildAddToVortexTubePanel()
                  : (_selectedCategoryIndex == 1
                      ? _buildPlaylistsManagerPanel()
                      : (_selectedCategoryIndex == 2
                          ? _buildEpgGuidePanel()
                          : _buildAboutPanel())))),
    );
  }

  // -------------------------------------------------------------
  // PANEL 1: ADD TO VORTEXTUBE
  // -------------------------------------------------------------
  Widget _buildAddToVortexTubePanel() {
    final liveCategories = [
      {'name': 'Live Sports 4K', 'desc': 'Premier League, UFC, NBA, F1', 'icon': Icons.sports_soccer_rounded},
      {'name': 'News 24/7 Global', 'desc': 'BBC, CNN, Sky News HD, Al Jazeera', 'icon': Icons.newspaper_rounded},
      {'name': 'Entertainment & General', 'desc': 'USA, UK & European Channels', 'icon': Icons.tv_rounded},
      {'name': 'AF | AFRICA Channels', 'desc': 'SuperSport, DStv, Francophone', 'icon': Icons.public_rounded},
      {'name': 'Music & Concerts', 'desc': 'MTV, Trace, Clubland, 4K Beats', 'icon': Icons.music_note_rounded},
      {'name': 'Kids & Family', 'desc': 'Cartoon Network, Disney+, Nick', 'icon': Icons.child_care_rounded},
    ];

    final vodCategories = [
      {'name': 'Action & Adventure', 'desc': 'Latest Blockbusters, Marvel, 4K HDR', 'icon': Icons.local_fire_department_rounded},
      {'name': 'Sci-Fi & Fantasy', 'desc': 'Cyberpunk, Space Operas & Futuristic', 'icon': Icons.rocket_launch_rounded},
      {'name': 'Crime Thrillers & Mystery', 'desc': 'Noir, Heist, Psychological & Whodunit', 'icon': Icons.fingerprint_rounded},
      {'name': 'Drama & Award Winners', 'desc': 'Oscar Winners, Cannes Selections', 'icon': Icons.masks_rounded},
    ];

    final seriesCategories = [
      {'name': 'Trending & Top Rated TV', 'desc': 'HBO, Netflix, Apple TV+, Prime', 'icon': Icons.trending_up_rounded},
      {'name': 'Sci-Fi & Mystery Series', 'desc': 'Black Mirror, Stranger Things, Dark', 'icon': Icons.smart_display_rounded},
      {'name': 'Crime & Docuseries', 'desc': 'True Crime, Investigative, Historical', 'icon': Icons.gavel_rounded},
      {'name': 'Animation & Anime', 'desc': 'Shonen, Seinen, Adult Animated Series', 'icon': Icons.mood_rounded},
    ];

    List<Map<String, dynamic>> activeList;
    if (_categoryGroupIndex == 0) {
      activeList = liveCategories;
    } else if (_categoryGroupIndex == 1) {
      activeList = vodCategories;
    } else {
      activeList = seriesCategories;
    }

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
                  'Add to VortexTube',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Select and favorite categories across Live TV, Movies / VOD, and Series to display on your home shelves',
                  style: TextStyle(color: Color(0xFF828290), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 3-Segmented Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF17171E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF252532)),
          ),
          child: Row(
            children: [
              _buildTypeTab(0, 'Live TV', Icons.live_tv_rounded),
              _buildTypeTab(1, 'Movies / VOD', Icons.movie_rounded),
              _buildTypeTab(2, 'Series', Icons.video_library_rounded),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('CHANNELS & CATEGORIES', style: TextStyle(color: Color(0xFF737380), fontSize: 11, fontWeight: FontWeight.bold)),
            Text('Press OK to pin/unpin shelf', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),

        // 2-Column Grid of Category Toggle Cards
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 3.8,
            ),
            itemCount: activeList.length,
            itemBuilder: (context, idx) {
              final cat = activeList[idx];
              final catName = cat['name'] as String;
              final catDesc = cat['desc'] as String;
              final catIcon = cat['icon'] as IconData;
              final isFav = _favoriteCategories.contains(catName);
              final isCardFocused = _isRightPaneFocused && _rightPaneFocusIndex == idx;

              return InkWell(
                onTap: () async {
                  final newFav = await StorageService.toggleFavoriteCategory(catName);
                  setState(() {
                    if (newFav) {
                      _favoriteCategories.add(catName);
                    } else {
                      _favoriteCategories.remove(catName);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCardFocused ? Colors.white : const Color(0xFF17171D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCardFocused ? Colors.white : (isFav ? const Color(0xFF4A4A4A) : const Color(0xFF242430)),
                      width: isCardFocused ? 2 : 1,
                    ),
                    boxShadow: isCardFocused
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 16,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCardFocused
                                  ? const Color(0xFFE5E5EA)
                                  : (isFav ? const Color(0xFF33333D) : const Color(0xFF21212A)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              catIcon,
                              size: 18,
                              color: isCardFocused ? Colors.black : (isFav ? Colors.white : const Color(0xFF8D8D9B)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                catName,
                                style: TextStyle(
                                  color: isCardFocused ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                catDesc,
                                style: TextStyle(
                                  color: isCardFocused ? const Color(0xFF555555) : const Color(0xFFA1A1AA),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFav
                              ? (isCardFocused ? Colors.black : const Color(0xFF4A4A4A))
                              : Colors.transparent,
                          border: isFav ? null : Border.all(color: const Color(0xFF3B3B4A)),
                        ),
                        child: isFav
                            ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: isCardFocused ? Colors.white : Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom status & Reset
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF202028), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF4A4A4A), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Pinned shelves update automatically on VortexTube player home',
                    style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () async {
                  for (final c in _favoriteCategories.toList()) {
                    await StorageService.toggleFavoriteCategory(c);
                  }
                  setState(() {
                    _favoriteCategories.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4D4D8),
                  side: const BorderSide(color: Color(0xFF2C2C38)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Reset All Shelves', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTab(int index, String label, IconData icon) {
    final isSelected = _categoryGroupIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _categoryGroupIndex = index;
            _rightPaneFocusIndex = 0;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 6)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.black : const Color(0xFF8D8D9B)),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFF8D8D9B),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PANEL 2: PLAYLISTS MANAGER
  // -------------------------------------------------------------
  Widget _buildPlaylistsManagerPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Playlists Manager',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Switch default IPTV provider, re-index categories or manage login streams',
          style: TextStyle(color: Color(0xFF828290), fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Quick Add Button
        InkWell(
          onTap: _openAddPortal,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A4A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('+', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.normal)),
                SizedBox(width: 8),
                Text('Add New Playlist / Portal', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text('ACTIVE PLAYLISTS', style: TextStyle(color: Color(0xFF737380), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            itemCount: _playlists.length,
            itemBuilder: (context, idx) {
              final pl = _playlists[idx];
              final isPlFocused = _isRightPaneFocused && _rightPaneFocusIndex == idx;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isPlFocused ? Colors.white : (pl.isActive ? const Color(0xFF1A1A22) : const Color(0xFF17171D)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPlFocused ? Colors.white : (pl.isActive ? Colors.white70 : const Color(0xFF252530)),
                    width: isPlFocused ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPlFocused ? const Color(0xFFE5E5EA) : const Color(0xFF21212A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            pl.isStalker
                                ? Icons.router_rounded
                                : pl.isXtreamCodes
                                    ? Icons.dns_rounded
                                    : Icons.playlist_play_rounded,
                            size: 18,
                            color: isPlFocused ? Colors.black : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pl.name,
                                  style: TextStyle(
                                    color: isPlFocused ? Colors.black : Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPlFocused ? const Color(0xFFCCCCCC) : const Color(0xFF282828),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    pl.isStalker ? 'DEFAULT PORTAL' : 'Xtream Codes',
                                    style: TextStyle(
                                      color: isPlFocused ? Colors.black : const Color(0xFFD4D4D8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              pl.isStalker
                                  ? 'Stalker Portal • MAC ${pl.macAddress ?? '00:1A:79:B4:42:19'}'
                                  : 'Xtream Codes • 12,480 Channels • 44k VOD',
                              style: TextStyle(
                                color: isPlFocused ? const Color(0xFF555555) : const Color(0xFF828292),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openEditPortal(pl),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isPlFocused ? Colors.black : const Color(0xFFD4D4D8),
                            side: BorderSide(color: isPlFocused ? Colors.black : const Color(0xFF323240)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text('Edit', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 10),
                        if (pl.isActive)
                          Row(
                            children: [
                              Text(
                                'Active Output',
                                style: TextStyle(color: isPlFocused ? Colors.black : const Color(0xFFD4D4D8), fontSize: 11),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPlFocused ? Colors.black : Colors.white,
                                ),
                                child: Icon(Icons.check_rounded, size: 14, color: isPlFocused ? Colors.white : Colors.black),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: () async {
                              await StorageService.setActivePlaylistId(pl.id);
                              await _loadData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF24242F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Use', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PANEL 3: ADD / EDIT PORTAL WIZARD
  // -------------------------------------------------------------
  Widget _buildWizardPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              onPressed: () => setState(() => _isWizardOpen = false),
            ),
            const SizedBox(width: 8),
            Text(
              _editingPlaylist != null ? 'Edit Playlist / Portal' : 'Add New Playlist / Portal',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Radio selector
        Row(
          children: [
            _buildWizardRadio(PortalType.xtream, 'Xtream Codes'),
            const SizedBox(width: 10),
            _buildWizardRadio(PortalType.m3u, 'M3U URL / File'),
            const SizedBox(width: 10),
            _buildWizardRadio(PortalType.stalker, 'Stalker MAC'),
          ],
        ),
        const SizedBox(height: 18),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormField('Playlist Name', _playlistNameController, 'e.g. My IPTV Provider'),
                const SizedBox(height: 14),
                _buildFormField(
                  _wizardPortalType == PortalType.stalker ? 'Portal URL' : 'Server URL / Portal Domain',
                  _serverUrlController,
                  _wizardPortalType == PortalType.stalker ? 'http://stalker-server.net/c/' : 'http://domain.com:port',
                ),
                const SizedBox(height: 14),
                if (_wizardPortalType == PortalType.xtream) ...[
                  Row(
                    children: [
                      Expanded(child: _buildFormField('Username', _usernameController, 'Enter username')),
                      const SizedBox(width: 14),
                      Expanded(child: _buildFormField('Password / PIN', _passwordController, 'Enter password', obscure: true)),
                    ],
                  ),
                ] else if (_wizardPortalType == PortalType.stalker) ...[
                  _buildFormField('MAC Address', _macAddressController, '00:1A:79:XX:XX:XX'),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _savePortal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4A4A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _isWizardOpen = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD4D4D8),
                        side: const BorderSide(color: Color(0xFF2E2E38)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWizardRadio(PortalType type, String label) {
    final isSelected = _wizardPortalType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _wizardPortalType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFF181820),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2A2A38)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFFD4D4D8),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, String hint, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF888899), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF181820),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2C2C3A)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF555566), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PANEL 4: EPG & TV GUIDE
  // -------------------------------------------------------------
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
                Text('EPG & TV Guide', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Program guide synchronization, timezone offsets, and XMLTV source URLs', style: TextStyle(color: Color(0xFF828290), fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF063319),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F5132)),
              ),
              child: const Text('Status: Synced 18m ago', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF17171D), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF262633))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Time Shift Offset', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
                    SizedBox(height: 6),
                    Text('UTC +01:00 (Auto)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF17171D), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF262633))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Auto-Update Frequency', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
                    SizedBox(height: 6),
                    Text('Every 6 Hours', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF16161D), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF262633))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('EPG Timeline Cache: 48 Hours Loaded', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('9,812 / 9,812 channels mapped', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: const Color(0xFF20202A),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFE50914), Color(0xFF10B981)]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PANEL 5: ABOUT VORTEXTUBE
  // -------------------------------------------------------------
  Widget _buildAboutPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('About VortexTube', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Your TV Friendly Player for better user experience and better personalization.', style: TextStyle(color: Color(0xFF828290), fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF450A0A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF991B1B)),
              ),
              child: const Text('Developed By CK', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16161D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF262633)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.system_update_rounded, color: Color(0xFFFF0033), size: 28),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('App Updates', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Directly update when new version is available', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4A4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildRemoteFooterLegend() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1C1C24), width: 1)),
      ),
      child: Row(
        children: [
          _buildKeyBadge('▲ / ▼', 'Navigate Items'),
          const SizedBox(width: 24),
          _buildKeyBadge('◄ / ►', 'Switch Panes'),
          const SizedBox(width: 24),
          _buildKeyBadge('OK / ENTER', 'Select / Toggle'),
          const SizedBox(width: 24),
          _buildKeyBadge('BACK / ESC', 'Return to Left Nav'),
        ],
      ),
    );
  }

  Widget _buildKeyBadge(String keyText, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A22),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2E2E3A)),
          ),
          child: Text(keyText, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontFamily: 'monospace')),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF828292), fontSize: 11)),
      ],
    );
  }
}
