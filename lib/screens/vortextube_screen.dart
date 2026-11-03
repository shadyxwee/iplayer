import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../services/vortextube_service.dart';
import '../widgets/smooth_page_route.dart';
import 'content_grid_screen.dart';
import 'live_tv_screen.dart';
import 'mobile_video_player_screen.dart';
import 'series_grid_screen.dart';
import 'settings_screen.dart';
import 'video_player_screen.dart';

enum VortexNavTarget {
  home,
  search,
  movies,
  liveTv,
  series,
  settings,
  dashboard,
}

enum VortexZone { sidebar, searchBar, shelves }

class VortexTubeScreen extends StatefulWidget {
  const VortexTubeScreen({super.key});

  @override
  State<VortexTubeScreen> createState() => _VortexTubeScreenState();
}

class _VortexTubeScreenState extends State<VortexTubeScreen> {
  List<VortexShelf> _shelves = [];
  bool _isLoading = true;

  // Spatial Navigation State
  VortexZone _currentZone = VortexZone.shelves;
  int _focusedNavIndex = 0;
  int _focusedShelfIndex = 0;
  int _focusedItemIndex = 0;

  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();
  final Map<int, ScrollController> _shelfScrollControllers = {};

  final List<Map<String, dynamic>> _navItems = [
    {'target': VortexNavTarget.home, 'icon': Icons.home_rounded, 'label': 'Home'},
    {'target': VortexNavTarget.search, 'icon': Icons.search_rounded, 'label': 'Search'},
    {'target': VortexNavTarget.liveTv, 'icon': Icons.live_tv_rounded, 'label': 'Live TV'},
    {'target': VortexNavTarget.movies, 'icon': Icons.movie_outlined, 'label': 'Movies'},
    {'target': VortexNavTarget.series, 'icon': Icons.video_collection_outlined, 'label': 'Series'},
    {'target': VortexNavTarget.settings, 'icon': Icons.settings_outlined, 'label': 'Settings'},
    {'target': VortexNavTarget.dashboard, 'icon': Icons.dashboard_outlined, 'label': 'Go To Home'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _mainScrollController.dispose();
    for (final c in _shelfScrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    final shelves = await VortexTubeService.getPersonalizedFeed();
    if (mounted) {
      setState(() {
        _shelves = shelves;
        _isLoading = false;
        _focusedShelfIndex = 0;
        _focusedItemIndex = 0;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
        setState(() => _currentZone = VortexZone.shelves);
        return;
      }
      Navigator.pop(context);
      return;
    }

    if (_searchFocusNode.hasFocus) {
      if (key == LogicalKeyboardKey.arrowDown) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
        setState(() => _currentZone = VortexZone.shelves);
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
        case VortexZone.shelves:
          if (_focusedShelfIndex > 0) {
            _focusedShelfIndex--;
            _focusedItemIndex = 0;
            _ensureVisibleShelf(_focusedShelfIndex);
          } else {
            _currentZone = VortexZone.searchBar;
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
          if (_shelves.isNotEmpty) {
            _currentZone = VortexZone.shelves;
            _focusedShelfIndex = 0;
            _focusedItemIndex = 0;
          }
          break;
        case VortexZone.shelves:
          if (_focusedShelfIndex < _shelves.length - 1) {
            _focusedShelfIndex++;
            _focusedItemIndex = 0;
            _ensureVisibleShelf(_focusedShelfIndex);
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
        case VortexZone.shelves:
          if (_focusedItemIndex > 0) {
            _focusedItemIndex--;
            _ensureVisibleItem(_focusedShelfIndex, _focusedItemIndex);
          } else {
            _currentZone = VortexZone.sidebar;
          }
          break;
      }
    });
  }

  void _moveRight() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          if (_shelves.isNotEmpty) {
            _currentZone = VortexZone.shelves;
            _ensureVisibleShelf(_focusedShelfIndex);
            _ensureVisibleItem(_focusedShelfIndex, _focusedItemIndex);
          } else {
            _currentZone = VortexZone.searchBar;
          }
          break;
        case VortexZone.searchBar:
          break;
        case VortexZone.shelves:
          if (_focusedShelfIndex < _shelves.length) {
            final shelf = _shelves[_focusedShelfIndex];
            if (_focusedItemIndex < shelf.items.length - 1) {
              _focusedItemIndex++;
              _ensureVisibleItem(_focusedShelfIndex, _focusedItemIndex);
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
        _handleNavAction(nav);
        break;
      case VortexZone.searchBar:
        _searchFocusNode.requestFocus();
        break;
      case VortexZone.shelves:
        if (_focusedShelfIndex < _shelves.length) {
          final shelf = _shelves[_focusedShelfIndex];
          if (_focusedItemIndex < shelf.items.length) {
            final item = shelf.items[_focusedItemIndex];
            _playItem(item);
          }
        }
        break;
    }
  }

  void _handleNavAction(VortexNavTarget target) {
    switch (target) {
      case VortexNavTarget.home:
        _loadFeed();
        break;
      case VortexNavTarget.search:
        _searchFocusNode.requestFocus();
        break;
      case VortexNavTarget.liveTv:
        Navigator.push(context, SmoothPageRoute(child: const LiveTVScreen())).then((_) => _loadFeed());
        break;
      case VortexNavTarget.movies:
        Navigator.push(
          context,
          SmoothPageRoute(
            child: const ContentGridScreen(contentType: ContentType.movie, title: 'Movies'),
          ),
        ).then((_) => _loadFeed());
        break;
      case VortexNavTarget.series:
        Navigator.push(context, SmoothPageRoute(child: const SeriesGridScreen())).then((_) => _loadFeed());
        break;
      case VortexNavTarget.settings:
        Navigator.push(context, SmoothPageRoute(child: const SettingsScreen())).then((_) => _loadFeed());
        break;
      case VortexNavTarget.dashboard:
        Navigator.pop(context);
        break;
    }
  }

  void _playItem(Channel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Platform.isAndroid
            ? MobileVideoPlayerScreen(channel: item)
            : VideoPlayerScreen(channel: item),
      ),
    ).then((_) => _loadFeed());
  }

  void _ensureVisibleShelf(int shelfIndex) {
    if (!_mainScrollController.hasClients) return;
    const double shelfHeight = 270.0;
    final double viewportHeight = _mainScrollController.position.viewportDimension;
    final double targetOffset = (shelfIndex * shelfHeight) - (viewportHeight / 3);
    final double clampedOffset = targetOffset.clamp(0.0, _mainScrollController.position.maxScrollExtent);

    _mainScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _ensureVisibleItem(int shelfIndex, int itemIndex) {
    final controller = _shelfScrollControllers[shelfIndex];
    if (controller == null || !controller.hasClients) return;

    final isCircular = _shelves[shelfIndex].isCircular;
    final double itemWidth = isCircular ? 130.0 : 190.0;
    final double viewportWidth = controller.position.viewportDimension;
    final double targetOffset = (itemIndex * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);
    final double clampedOffset = targetOffset.clamp(0.0, controller.position.maxScrollExtent);

    controller.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F), // YouTube dark background
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
                          : _shelves.isEmpty
                              ? _buildEmptyState()
                              : _buildShelvesList(),
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
        color: Color(0xFF161616),
        border: Border(right: BorderSide(color: Color(0xFF282828), width: 1)),
      ),
      child: Column(
        children: [
          // VortexTube Logo Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000), // YouTube red
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                const Text(
                  'VortexTube',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF282828), height: 1),
          const SizedBox(height: 12),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isFocused = _currentZone == VortexZone.sidebar && index == _focusedNavIndex;
                final isHome = item['target'] == VortexNavTarget.home;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentZone = VortexZone.sidebar;
                      _focusedNavIndex = index;
                    });
                    _handleNavAction(item['target'] as VortexNavTarget);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isFocused
                          ? Colors.white.withValues(alpha: 0.15)
                          : isHome
                              ? const Color(0xFF282828)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isHome || isFocused ? Colors.white : const Color(0xFFAAAAAA),
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isHome || isFocused ? Colors.white : const Color(0xFFAAAAAA),
                            fontSize: 14,
                            fontWeight: isHome || isFocused ? FontWeight.bold : FontWeight.w500,
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
      ),
    );
  }

  Widget _buildTopHeader() {
    final isFocused = _currentZone == VortexZone.searchBar;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 1)),
      ),
      child: Row(
        children: [
          // YouTube-style Search Capsule
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540),
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isFocused ? Colors.white : const Color(0xFF303030),
                    width: isFocused ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.search_rounded, color: Color(0xFF888888), size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search your loved channels, movies, and series...',
                          hintStyle: TextStyle(color: Color(0xFF717171), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                child: ContentGridScreen(contentType: ContentType.live, title: 'Search: $value'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF0000), size: 54),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your VortexTube Feed is Empty',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'VortexTube is your private personalized home feed.\nFavorite categories or individual channels, movies, and series to populate recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, SmoothPageRoute(child: const LiveTVScreen())).then((_) => _loadFeed());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.live_tv_rounded),
              label: const Text('Browse Live TV & Favorite Categories', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelvesList() {
    return ListView.builder(
      controller: _mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
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
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf Header
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
          const SizedBox(height: 14),

          // Horizontal Row of Items
          SizedBox(
            height: shelf.isCircular ? 130 : 200,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: shelf.items.length,
              itemBuilder: (context, itemIndex) {
                final item = shelf.items[itemIndex];
                final isFocused = _currentZone == VortexZone.shelves &&
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
          _currentZone = VortexZone.shelves;
          _focusedShelfIndex = shelfIndex;
          _focusedItemIndex = itemIndex;
        });
        _playItem(item);
      },
      child: Container(
        width: 110,
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
                color: const Color(0xFF242424),
                border: Border.all(
                  color: isFocused ? Colors.white : Colors.transparent,
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
              child: ClipOval(
                child: item.logo != null && item.logo!.isNotEmpty
                    ? Image.network(
                        item.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white70, size: 30),
                      )
                    : const Icon(Icons.tv, color: Colors.white70, size: 30),
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
          _currentZone = VortexZone.shelves;
          _focusedShelfIndex = shelfIndex;
          _focusedItemIndex = itemIndex;
        });
        _playItem(item);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 170,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused ? Colors.white : const Color(0xFF2A2A2A),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: item.logo != null && item.logo!.isNotEmpty
                    ? Image.network(
                        item.logo!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF262626),
                          child: const Center(child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 40)),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF262626),
                        child: const Center(child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 40)),
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
}
