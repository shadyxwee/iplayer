import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/vortextube_service.dart';
import 'mobile_video_player_screen.dart';
import '../widgets/smooth_page_route.dart';
import 'settings_screen.dart';
import 'video_player_screen.dart';

enum VortexNavTarget {
  profile,
  search,
  home,
  movies,
  liveTv,
  series,
  addMore,
  goToHome,
  settings,
}

enum VortexZone { sidebar, searchBar, content }

class VortexTubeScreen extends StatefulWidget {
  const VortexTubeScreen({super.key});

  @override
  State<VortexTubeScreen> createState() => _VortexTubeScreenState();
}

class _VortexTubeScreenState extends State<VortexTubeScreen> {
  // Navigation & View State
  VortexNavTarget _activeNav = VortexNavTarget.home;
  VortexZone _currentZone = VortexZone.content;
  int _focusedNavIndex = 2; // Home is index 2

  // Feed & Scoped Content Data
  List<VortexShelf> _shelves = [];
  List<Channel> _scopedItems = [];
  Set<String> _favoriteCategories = {};
  Playlist? _activePlaylist;
  bool _isLoading = true;

  // Infinite Scroll & Pagination
  int _displayedCount = 24;
  final int _pageSize = 24;

  // Search State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();

  // Scroll Controllers
  final ScrollController _mainScrollController = ScrollController();
  final Map<int, ScrollController> _shelfScrollControllers = {};

  // Focus indices in content zone
  int _focusedShelfIndex = 0;
  int _focusedItemIndex = 0;
  int _focusedGridIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {'target': VortexNavTarget.profile, 'icon': Icons.account_circle_outlined, 'label': 'Playlist'},
    {'target': VortexNavTarget.search, 'icon': Icons.search_rounded, 'label': 'Search'},
    {'target': VortexNavTarget.home, 'icon': Icons.home_rounded, 'label': 'Home'},
    {'target': VortexNavTarget.movies, 'icon': Icons.movie_outlined, 'label': 'Movies'},
    {'target': VortexNavTarget.liveTv, 'icon': Icons.live_tv_rounded, 'label': 'Live TV'},
    {'target': VortexNavTarget.series, 'icon': Icons.video_collection_outlined, 'label': 'Series'},
    {'target': VortexNavTarget.addMore, 'icon': Icons.add_circle_outline_rounded, 'label': 'Add More'},
    {'target': VortexNavTarget.goToHome, 'icon': Icons.dashboard_outlined, 'label': 'Go To Home'},
    {'target': VortexNavTarget.settings, 'icon': Icons.settings_outlined, 'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _mainScrollController.removeListener(_onScroll);
    _mainScrollController.dispose();
    _screenFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    for (final c in _shelfScrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_mainScrollController.position.pixels >= _mainScrollController.position.maxScrollExtent - 200) {
      if (_displayedCount < _scopedItems.length) {
        setState(() {
          _displayedCount += _pageSize;
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final activeId = await PreferencesService.getActivePlaylistId();
    if (activeId != null) {
      _activePlaylist = await DatabaseService.getPlaylistById(activeId);
    }
    _activePlaylist ??= (await DatabaseService.getAllPlaylists()).firstOrNull;

    final favCats = await PreferencesService.getFavoriteCategories();
    _favoriteCategories = favCats.toSet();

    await _loadActiveViewContent();
  }

  Future<void> _loadActiveViewContent() async {
    if (_activeNav == VortexNavTarget.home) {
      final shelves = await VortexTubeService.getPersonalizedFeed();
      if (mounted) {
        setState(() {
          _shelves = shelves;
          _isLoading = false;
          _focusedShelfIndex = 0;
          _focusedItemIndex = 0;
        });
      }
    } else {
      // Scoped views for Movies, Live TV, Series, or Search
      final allChannels = await DatabaseService.getAllChannels();
      final lovedCategories = _favoriteCategories;

      // Filter strictly to user's loved categories or loved items
      var filtered = allChannels.where((c) {
        final isItemLoved = c.isFavorite;
        final isCatLoved = c.group != null && lovedCategories.contains(c.group!);
        return isItemLoved || isCatLoved;
      }).toList();

      if (_activeNav == VortexNavTarget.liveTv) {
        filtered = filtered.where((c) => c.contentType == ContentType.live).toList();
      } else if (_activeNav == VortexNavTarget.movies) {
        filtered = filtered.where((c) => c.contentType == ContentType.movie).toList();
      } else if (_activeNav == VortexNavTarget.series) {
        filtered = filtered.where((c) => c.contentType == ContentType.series).toList();
      }

      if (_searchQuery.trim().isNotEmpty) {
        filtered = filtered
            .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }

      // Sort by personalization score
      filtered.sort((a, b) => VortexTubeService.scoreItem(channel: b, lovedCategories: lovedCategories)
          .compareTo(VortexTubeService.scoreItem(channel: a, lovedCategories: lovedCategories)));

      if (mounted) {
        setState(() {
          _scopedItems = filtered;
          _displayedCount = _pageSize;
          _isLoading = false;
          _focusedGridIndex = 0;
        });
      }
    }
  }

  void _showAddMorePopup() async {
    final allChannels = await DatabaseService.getAllChannels();
    final categoriesByType = <ContentType, Set<String>>{
      ContentType.live: {},
      ContentType.movie: {},
      ContentType.series: {},
    };

    for (final c in allChannels) {
      if (c.group != null && c.group!.isNotEmpty) {
        categoriesByType[c.contentType]?.add(c.group!);
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF161616),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF282828)),
              ),
              child: Container(
                width: 580,
                height: 520,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded, color: Color(0xFFFF0000)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add to VortexTube',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFAAAAAA)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Favorite categories from your playlist to automatically populate your personalized shelves.',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF282828), height: 1),
                    Expanded(
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              indicatorColor: Color(0xFFFF0000),
                              labelColor: Colors.white,
                              unselectedLabelColor: Color(0xFF888888),
                              tabs: [
                                Tab(text: 'Live TV'),
                                Tab(text: 'Movies / VOD'),
                                Tab(text: 'Series'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildCategoryPickerList(
                                    categoriesByType[ContentType.live]!.toList()..sort(),
                                    setDialogState,
                                  ),
                                  _buildCategoryPickerList(
                                    categoriesByType[ContentType.movie]!.toList()..sort(),
                                    setDialogState,
                                  ),
                                  _buildCategoryPickerList(
                                    categoriesByType[ContentType.series]!.toList()..sort(),
                                    setDialogState,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Refresh feed when dialog closes
    final updatedFavs = await PreferencesService.getFavoriteCategories();
    setState(() {
      _favoriteCategories = updatedFavs.toSet();
    });
    _loadActiveViewContent();
  }

  Widget _buildCategoryPickerList(List<String> categories, StateSetter setDialogState) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories available in playlist', style: TextStyle(color: Color(0xFF888888))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isFav = _favoriteCategories.contains(cat);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: isFav ? const Color(0xFFFF0000).withValues(alpha: 0.1) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFav ? const Color(0xFFFF0000).withValues(alpha: 0.4) : const Color(0xFF282828),
            ),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              cat,
              style: TextStyle(
                color: isFav ? Colors.white : const Color(0xFFCCCCCC),
                fontWeight: isFav ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? const Color(0xFFFF0000) : const Color(0xFF666666),
              ),
              onPressed: () async {
                final isNowFav = await PreferencesService.toggleFavoriteCategory(cat);
                setDialogState(() {
                  if (isNowFav) {
                    _favoriteCategories.add(cat);
                  } else {
                    _favoriteCategories.remove(cat);
                  }
                });
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
        setState(() => _currentZone = VortexZone.content);
        return;
      }
      Navigator.pop(context);
      return;
    }

    if (_searchFocusNode.hasFocus) {
      if (key == LogicalKeyboardKey.arrowDown) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
        setState(() => _currentZone = VortexZone.content);
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _moveUp();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _moveDown();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _moveLeft();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _moveRight();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space) {
      _activateCurrent();
    }
  }

  void _moveUp() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          if (_focusedNavIndex > 0) {
            _focusedNavIndex--;
          }
          break;
        case VortexZone.searchBar:
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedShelfIndex > 0) {
              _focusedShelfIndex--;
              _focusedItemIndex = 0;
            } else {
              _currentZone = VortexZone.searchBar;
            }
          } else {
            if (_focusedGridIndex >= 4) {
              _focusedGridIndex -= 4;
            } else {
              _currentZone = VortexZone.searchBar;
            }
          }
          break;
      }
    });
  }

  void _moveDown() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          if (_focusedNavIndex < _navItems.length - 1) {
            _focusedNavIndex++;
          }
          break;
        case VortexZone.searchBar:
          _currentZone = VortexZone.content;
          _focusedShelfIndex = 0;
          _focusedItemIndex = 0;
          _focusedGridIndex = 0;
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedShelfIndex < _shelves.length - 1) {
              _focusedShelfIndex++;
              _focusedItemIndex = 0;
            }
          } else {
            if (_focusedGridIndex + 4 < _scopedItems.length) {
              _focusedGridIndex += 4;
            }
          }
          break;
      }
    });
  }

  void _moveLeft() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          break;
        case VortexZone.searchBar:
          _currentZone = VortexZone.sidebar;
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedItemIndex > 0) {
              _focusedItemIndex--;
            } else {
              _currentZone = VortexZone.sidebar;
            }
          } else {
            if (_focusedGridIndex % 4 != 0) {
              _focusedGridIndex--;
            } else {
              _currentZone = VortexZone.sidebar;
            }
          }
          break;
      }
    });
  }

  void _moveRight() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          _currentZone = VortexZone.content;
          break;
        case VortexZone.searchBar:
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedShelfIndex < _shelves.length) {
              final shelf = _shelves[_focusedShelfIndex];
              if (_focusedItemIndex < shelf.items.length - 1) {
                _focusedItemIndex++;
              }
            }
          } else {
            if (_focusedGridIndex < _scopedItems.length - 1 && (_focusedGridIndex + 1) % 4 != 0) {
              _focusedGridIndex++;
            }
          }
          break;
      }
    });
  }

  void _activateCurrent() {
    switch (_currentZone) {
      case VortexZone.sidebar:
        final nav = _navItems[_focusedNavIndex]['target'] as VortexNavTarget;
        _selectNavTarget(nav);
        break;
      case VortexZone.searchBar:
        _searchFocusNode.requestFocus();
        break;
      case VortexZone.content:
        if (_activeNav == VortexNavTarget.home) {
          if (_focusedShelfIndex < _shelves.length) {
            final shelf = _shelves[_focusedShelfIndex];
            if (_focusedItemIndex < shelf.items.length) {
              _playItem(shelf.items[_focusedItemIndex]);
            }
          }
        } else {
          if (_focusedGridIndex < _scopedItems.length) {
            _playItem(_scopedItems[_focusedGridIndex]);
          }
        }
        break;
    }
  }

  void _selectNavTarget(VortexNavTarget target) {
    if (target == VortexNavTarget.addMore) {
      _showAddMorePopup();
      return;
    }

    if (target == VortexNavTarget.goToHome) {
      Navigator.pop(context);
      return;
    }

    if (target == VortexNavTarget.settings) {
      Navigator.push(context, SmoothPageRoute(child: const SettingsScreen())).then((_) => _loadActiveViewContent());
      return;
    }

    if (target == VortexNavTarget.search) {
      _searchFocusNode.requestFocus();
      return;
    }

    setState(() {
      _activeNav = target;
      _isLoading = true;
    });
    _loadActiveViewContent();
  }

  void _playItem(Channel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Platform.isAndroid
            ? MobileVideoPlayerScreen(channel: item)
            : VideoPlayerScreen(channel: item),
      ),
    ).then((_) => _loadActiveViewContent());
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
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF0000)))
                          : _activeNav == VortexNavTarget.home
                              ? (_shelves.isEmpty ? _buildEmptyState() : _buildShelvesList())
                              : (_scopedItems.isEmpty ? _buildEmptyScopedState() : _buildScopedGridView()),
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
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(right: BorderSide(color: Color(0xFF222222), width: 1)),
      ),
      child: Column(
        children: [
          // Profile / Playlist Name Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, color: Color(0xFFAAAAAA), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _activePlaylist?.name ?? 'VortexTube',
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarButton(VortexNavTarget.search, Icons.search_rounded, 'Search', 1),
                _buildSidebarButton(VortexNavTarget.home, Icons.home_rounded, 'Home', 2),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFF222222), height: 1),
                ),
                _buildSidebarButton(VortexNavTarget.movies, Icons.movie_outlined, 'Movies', 3),
                _buildSidebarButton(VortexNavTarget.liveTv, Icons.live_tv_rounded, 'Live TV', 4),
                _buildSidebarButton(VortexNavTarget.series, Icons.video_collection_outlined, 'Series', 5),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFF222222), height: 1),
                ),
                _buildSidebarButton(VortexNavTarget.addMore, Icons.add_circle_outline_rounded, 'Add More', 6),
              ],
            ),
          ),

          // Bottom Section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              children: [
                const Divider(color: Color(0xFF222222), height: 1),
                const SizedBox(height: 8),
                _buildSidebarButton(VortexNavTarget.goToHome, Icons.logout_rounded, 'Go To Home', 7),
                _buildSidebarButton(VortexNavTarget.settings, Icons.settings_outlined, 'Settings', 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(VortexNavTarget target, IconData icon, String label, int navIndex) {
    final isActive = _activeNav == target;
    final isFocused = _currentZone == VortexZone.sidebar && _focusedNavIndex == navIndex;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentZone = VortexZone.sidebar;
            _focusedNavIndex = navIndex;
          });
          _selectNavTarget(target);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFF1F1F1) // Active white pill
                : isFocused
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : (isFocused ? Colors.white : const Color(0xFFAAAAAA)),
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.black : (isFocused ? Colors.white : const Color(0xFFAAAAAA)),
                    fontSize: 14.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final isFocused = _currentZone == VortexZone.searchBar;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search Capsule
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isFocused ? Colors.white : Colors.transparent,
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded, color: Color(0xFFAAAAAA), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search VortexTube...',
                      hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _loadActiveViewContent();
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadActiveViewContent();
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.clear, color: Color(0xFF888888), size: 18),
                    ),
                  ),
              ],
            ),
          ),

          // VortexTube Logo Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'VortexTube',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF0000), size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Personalized VortexTube Feed',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'VortexTube only showcases content from your favorite categories and loved items.\nClick "Add More" to favorite categories from your playlist.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddMorePopup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add Categories Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScopedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off_rounded, color: Color(0xFF666666), size: 48),
            SizedBox(height: 16),
            Text(
              'No items in loved categories matching this filter.',
              style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Use "Add More" on the sidebar to add more favorite categories to VortexTube.',
              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelvesList() {
    return ListView.builder(
      controller: _mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 40),
      itemCount: _shelves.length,
      itemBuilder: (context, shelfIndex) {
        final shelf = _shelves[shelfIndex];
        return _buildShelfSection(shelf, shelfIndex);
      },
    );
  }

  Widget _buildShelfSection(VortexShelf shelf, int shelfIndex) {
    final controller = _shelfScrollControllers.putIfAbsent(
      shelfIndex,
      () => ScrollController(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                shelf.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                shelf.subtitle,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: shelf.isCircular ? 130 : 210,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: shelf.items.length,
              itemBuilder: (context, itemIndex) {
                final item = shelf.items[itemIndex];
                final isFocused = _currentZone == VortexZone.content &&
                    _focusedShelfIndex == shelfIndex &&
                    _focusedItemIndex == itemIndex;

                return shelf.isCircular
                    ? _buildCircularCard(item, isFocused, shelfIndex, itemIndex)
                    : _buildRectangularCard(item, isFocused, shelfIndex, itemIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularCard(Channel item, bool isFocused, int shelfIndex, int itemIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentZone = VortexZone.content;
          _focusedShelfIndex = shelfIndex;
          _focusedItemIndex = itemIndex;
        });
        _playItem(item);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isFocused ? 76 : 70,
              height: isFocused ? 76 : 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1F1F1F),
                border: Border.all(
                  color: isFocused ? Colors.white : const Color(0xFF333333),
                  width: isFocused ? 3 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipOval(
                child: item.logo != null && item.logo!.isNotEmpty
                    ? Image.network(
                        item.logo!,
                        fit: BoxFit.contain, // Fixed: properly contained, not zoomed
                        errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white70, size: 28),
                      )
                    : const Icon(Icons.tv, color: Colors.white70, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: TextStyle(
                color: isFocused ? Colors.white : const Color(0xFFAAAAAA),
                fontSize: 12,
                fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRectangularCard(Channel item, bool isFocused, int shelfIndex, int itemIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentZone = VortexZone.content;
          _focusedShelfIndex = shelfIndex;
          _focusedItemIndex = itemIndex;
        });
        _playItem(item);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 280, // Aspect video ratio ~16:9 like YouTube TV
        margin: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFocused ? Colors.white : const Color(0xFF282828),
            width: isFocused ? 2.5 : 1,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Container(
                  color: const Color(0xFF181818),
                  child: Center(
                    child: item.logo != null && item.logo!.isNotEmpty
                        ? Image.network(
                            item.logo!,
                            width: double.infinity,
                            fit: BoxFit.contain, // Fixed: fit.contain prevents excessive zooming
                            errorBuilder: (_, __, ___) => const Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 40),
                          )
                        : const Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: isFocused ? Colors.white : const Color(0xFFE0E0E0),
                      fontSize: 14,
                      fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.group ?? 'Loved Item',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopedGridView() {
    final displayedItems = _scopedItems.take(_displayedCount).toList();

    return GridView.builder(
      controller: _mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.35,
      ),
      itemCount: displayedItems.length,
      itemBuilder: (context, index) {
        final item = displayedItems[index];
        final isFocused = _currentZone == VortexZone.content && _focusedGridIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentZone = VortexZone.content;
              _focusedGridIndex = index;
            });
            _playItem(item);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused ? Colors.white : const Color(0xFF282828),
                width: isFocused ? 2.5 : 1,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Container(
                      color: const Color(0xFF181818),
                      child: Center(
                        child: item.logo != null && item.logo!.isNotEmpty
                            ? Image.network(
                                item.logo!,
                                width: double.infinity,
                                fit: BoxFit.contain, // Fixed: logo properly contained
                                errorBuilder: (_, __, ___) => const Icon(Icons.movie_outlined, color: Colors.white24, size: 40),
                              )
                            : const Icon(Icons.movie_outlined, color: Colors.white24, size: 40),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: isFocused ? Colors.white : const Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.group ?? 'Loved',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
