import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models.dart';
import '../../core/storage_service.dart';
import '../../core/image_cache_service.dart';
import '../settings/settings_screen.dart';

enum VortexNavTarget {
  search,
  home,
  movies,
  liveTv,
  series,
  settings,
}

enum VortexZone { sidebar, searchBar, filterBar, content }

enum VortexSortOption {
  recommended,
  nameAsc,
  nameDesc,
  releaseDate,
}

enum VortexFilterType { all, recent, inProgress, category }

class VortexActiveFilter {
  final VortexFilterType type;
  final String? categoryName;

  const VortexActiveFilter._(this.type, [this.categoryName]);

  static const all = VortexActiveFilter._(VortexFilterType.all);
  static const recent = VortexActiveFilter._(VortexFilterType.recent);
  static const inProgress = VortexActiveFilter._(VortexFilterType.inProgress);
  static VortexActiveFilter category(String name) => VortexActiveFilter._(VortexFilterType.category, name);
}

class VortexTubeHomeScreen extends StatefulWidget {
  const VortexTubeHomeScreen({super.key});

  @override
  State<VortexTubeHomeScreen> createState() => _VortexTubeHomeScreenState();
}

class _VortexTubeHomeScreenState extends State<VortexTubeHomeScreen> {
  // Navigation State
  VortexNavTarget _activeNav = VortexNavTarget.home;
  VortexZone _currentZone = VortexZone.content;
  int _focusedNavIndex = 1; // 1: Home

  // Sidebar
  bool _isSidebarExpanded = true;

  // Filters & Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  String _searchQuery = '';
  VortexActiveFilter _activeFilter = VortexActiveFilter.all;
  final VortexSortOption _sortOption = VortexSortOption.recommended;

  // Data
  List<ChannelModel> _allChannels = [];
  List<ChannelModel> _scopedItems = [];
  List<ChannelModel> _filteredScopedItems = [];
  Set<String> _favoriteCategories = {};
  bool _isLoading = true;

  final ScrollController _mainScrollController = ScrollController();
  final List<Map<String, dynamic>> _navItems = [
    {'target': VortexNavTarget.search, 'icon': Icons.search_rounded, 'label': 'Search'},
    {'target': VortexNavTarget.home, 'icon': Icons.home_rounded, 'label': 'Home'},
    {'target': VortexNavTarget.movies, 'icon': Icons.movie_outlined, 'label': 'Movies'},
    {'target': VortexNavTarget.liveTv, 'icon': Icons.live_tv_rounded, 'label': 'Live TV'},
    {'target': VortexNavTarget.series, 'icon': Icons.video_collection_outlined, 'label': 'Series'},
    {'target': VortexNavTarget.settings, 'icon': Icons.settings_outlined, 'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _screenFocusNode.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await StorageService.getPlaylists();
    _favoriteCategories = await StorageService.getFavoriteCategories();
    _allChannels = await StorageService.getChannels();
    _loadActiveViewContent();
  }

  void _loadActiveViewContent() {
    List<ChannelModel> items;
    if (_activeNav == VortexNavTarget.liveTv) {
      items = _allChannels.where((c) => c.contentType == ContentType.live).toList();
    } else if (_activeNav == VortexNavTarget.movies) {
      items = _allChannels.where((c) => c.contentType == ContentType.movie).toList();
    } else if (_activeNav == VortexNavTarget.series) {
      items = _allChannels.where((c) => c.contentType == ContentType.series).toList();
    } else {
      items = _allChannels;
    }

    // Filter strictly to loved categories or favorited items
    var filtered = items.where((c) {
      final isItemLoved = c.isFavorite;
      final isCatLoved = c.group != null && _favoriteCategories.contains(c.group!);
      return isItemLoved || isCatLoved;
    }).toList();

    if (_searchQuery.trim().isNotEmpty) {
      filtered = filtered
          .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by rating & favorite
    filtered.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.rating.compareTo(a.rating);
    });

    _scopedItems = filtered;
    _applyFilter();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    var items = List<ChannelModel>.from(_scopedItems);
    switch (_activeFilter.type) {
      case VortexFilterType.all:
        break;
      case VortexFilterType.recent:
        items = items.where((c) => c.lastPlayed != null).toList()
          ..sort((a, b) => (b.lastPlayed ?? DateTime(2000)).compareTo(a.lastPlayed ?? DateTime(2000)));
        break;
      case VortexFilterType.inProgress:
        items = items.where((c) => c.watchedMilliseconds > 0).toList();
        break;
      case VortexFilterType.category:
        if (_activeFilter.categoryName != null) {
          items = items.where((c) => c.group == _activeFilter.categoryName).toList();
        }
        break;
    }

    switch (_sortOption) {
      case VortexSortOption.recommended:
        break;
      case VortexSortOption.nameAsc:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case VortexSortOption.nameDesc:
        items.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case VortexSortOption.releaseDate:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    setState(() {
      _filteredScopedItems = items;
    });
  }

  void _selectNavTarget(VortexNavTarget target) {
    if (target == VortexNavTarget.settings) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TVSettingsScreen()),
      ).then((_) => _loadInitialData());
      return;
    }

    if (target == VortexNavTarget.search) {
      setState(() {
        _activeNav = target;
        _currentZone = VortexZone.searchBar;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
      return;
    }

    _searchController.clear();
    _searchQuery = '';

    setState(() {
      _activeNav = target;
      _activeFilter = VortexActiveFilter.all;
      _isLoading = true;
    });

    _loadActiveViewContent();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_currentZone == VortexZone.sidebar) {
        if (_focusedNavIndex < _navItems.length - 1) {
          setState(() {
            _focusedNavIndex++;
            final nav = _navItems[_focusedNavIndex]['target'] as VortexNavTarget;
            _selectNavTarget(nav);
          });
        }
      } else if (_currentZone == VortexZone.searchBar) {
        setState(() => _currentZone = VortexZone.filterBar);
      } else if (_currentZone == VortexZone.filterBar) {
        setState(() => _currentZone = VortexZone.content);
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (_currentZone == VortexZone.sidebar) {
        if (_focusedNavIndex > 0) {
          setState(() {
            _focusedNavIndex--;
            final nav = _navItems[_focusedNavIndex]['target'] as VortexNavTarget;
            _selectNavTarget(nav);
          });
        }
      } else if (_currentZone == VortexZone.filterBar) {
        setState(() => _currentZone = VortexZone.searchBar);
      } else if (_currentZone == VortexZone.content) {
        setState(() => _currentZone = VortexZone.filterBar);
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (_currentZone == VortexZone.content || _currentZone == VortexZone.filterBar) {
        setState(() {
          _currentZone = VortexZone.sidebar;
          _isSidebarExpanded = true;
        });
      }
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (_currentZone == VortexZone.sidebar) {
        setState(() {
          _currentZone = VortexZone.content;
          _isSidebarExpanded = false;
        });
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
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          child: Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(),
                    _buildTopFilterBar(),
                    Expanded(
                      child: _isLoading
                          ? _buildSkeletonLoading()
                          : (_filteredScopedItems.isEmpty
                              ? _buildEmptyState()
                              : _buildContentGrid()),
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

  Widget _buildSidebar() {
    final double sidebarWidth = _isSidebarExpanded ? 290.0 : 80.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isSidebarExpanded = true),
      onExit: (_) => setState(() => _isSidebarExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: sidebarWidth,
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(right: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
        ),
        child: Column(
          children: [
            // Logo Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    const Text(
                      'VortexTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Nav Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildSidebarButton(VortexNavTarget.search, Icons.search_rounded, 'Search', 0),
                  _buildSidebarButton(VortexNavTarget.home, Icons.home_rounded, 'Home', 1),
                  _buildSidebarButton(VortexNavTarget.movies, Icons.movie_outlined, 'Movies', 2),
                  _buildSidebarButton(VortexNavTarget.liveTv, Icons.live_tv_rounded, 'Live TV', 3),
                  _buildSidebarButton(VortexNavTarget.series, Icons.video_collection_outlined, 'Series', 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Divider(color: Color(0xFF202020), height: 1),
                  ),
                  _buildSidebarButton(VortexNavTarget.settings, Icons.settings_outlined, 'Settings', 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarButton(VortexNavTarget target, IconData icon, String label, int navIndex) {
    final isFocused = _currentZone == VortexZone.sidebar && _focusedNavIndex == navIndex;
    final isActive = _activeNav == target;
    final isHighlighted = isFocused || (isActive && _currentZone != VortexZone.sidebar);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentZone = VortexZone.sidebar;
            _focusedNavIndex = navIndex;
          });
          _selectNavTarget(target);
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: _isSidebarExpanded ? 16 : 0),
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFFEEEEEE) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: isHighlighted ? Colors.black : const Color(0xFFA3A3A3), size: 22),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isHighlighted ? Colors.black : const Color(0xFFA3A3A3),
                    fontSize: 15,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _activeNav == VortexNavTarget.home
                    ? 'Home Feed'
                    : (_activeNav == VortexNavTarget.movies
                        ? 'Movies'
                        : (_activeNav == VortexNavTarget.liveTv ? 'Live Channels' : 'TV Series')),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_filteredScopedItems.length} items',
                  style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 11),
                ),
              ),
            ],
          ),
          // Search Capsule
          Container(
            width: 320,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF18181C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _currentZone == VortexZone.searchBar ? Colors.white : const Color(0xFF282830),
                width: _currentZone == VortexZone.searchBar ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF71717A), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search VortexTube...',
                      hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _loadActiveViewContent();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 12),
      child: Row(
        children: [
          _buildFilterChip('All', _activeFilter.type == VortexFilterType.all, () {
            setState(() {
              _activeFilter = VortexActiveFilter.all;
              _applyFilter();
            });
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Recent', _activeFilter.type == VortexFilterType.recent, () {
            setState(() {
              _activeFilter = VortexActiveFilter.recent;
              _applyFilter();
            });
          }),
          const SizedBox(width: 8),
          _buildFilterChip('In Progress', _activeFilter.type == VortexFilterType.inProgress, () {
            setState(() {
              _activeFilter = VortexActiveFilter.inProgress;
              _applyFilter();
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2C2C36)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFFD4D4D8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
    final isLive = _activeNav == VortexNavTarget.liveTv;

    return GridView.builder(
      controller: _mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLive ? 8 : 6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isLive ? 1.0 : (2 / 3.4),
      ),
      itemCount: _filteredScopedItems.length,
      itemBuilder: (context, idx) {
        final item = _filteredScopedItems[idx];
        return isLive ? _buildCircularLiveCard(item) : _buildPosterCard(item);
      },
    );
  }

  Widget _buildCircularLiveCard(ChannelModel item) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF17171C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF26262E)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF24242A),
              ),
              child: const Icon(Icons.tv_rounded, color: Colors.white70, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterCard(ChannelModel item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17171C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26262E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strict 2:3 aspect ratio poster with layout stability
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Container(
                color: const Color(0xFF141324),
                child: item.logo != null && item.logo!.isNotEmpty
                    ? Image(
                        image: TVImageCacheService.getCachedImageProvider(item.logo!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.movie_outlined, color: Colors.white24, size: 36),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.movie_outlined, color: Colors.white24, size: 36),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.group ?? 'Loved',
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border_rounded, color: Color(0xFFFF0000), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Your Personalized VortexTube Feed',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'VortexTube only showcases content from your favorite categories and loved items.\nVisit Settings to favorite categories from your playlist.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TVSettingsScreen(initialCategoryIndex: 0)),
              ).then((_) => _loadInitialData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text('Add Categories in Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: 3,
      itemBuilder: (context, idx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 160, height: 18, color: const Color(0xFF1E1E24)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, cIdx) => Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(color: const Color(0xFF17171C), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
