import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../models/series.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/series_parser.dart';
import '../services/vortextube_service.dart';
import '../widgets/smooth_page_route.dart';
import 'mobile_video_player_screen.dart';
import 'series_detail_screen.dart';
import 'playlist_manager_screen.dart';
import 'video_player_screen.dart';

enum VortexNavTarget {
  search,
  home,
  movies,
  liveTv,
  series,
  addMore,
  goToHome,
  settings,
}

enum _AddMoreFocusArea {
  closeButton,
  search,
  tabs,
  listRow,
  listHeart,
}

class _AddMoreVortexDialog extends StatefulWidget {
  final Map<ContentType, List<String>> categoriesByType;
  final Set<String> initialFavorites;
  final ValueChanged<Set<String>> onFavoritesChanged;

  const _AddMoreVortexDialog({
    required this.categoriesByType,
    required this.initialFavorites,
    required this.onFavoritesChanged,
  });

  @override
  State<_AddMoreVortexDialog> createState() => _AddMoreVortexDialogState();
}

class _AddMoreVortexDialogState extends State<_AddMoreVortexDialog> {
  late Set<String> _currentFavorites;
  int _activeTabIndex = 0; // 0: Live TV, 1: Movies / VOD, 2: Series
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _dialogKeyFocusNode = FocusNode();
  final ScrollController _listScrollController = ScrollController();

  _AddMoreFocusArea _focusArea = _AddMoreFocusArea.search;
  int _focusedRowIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentFavorites = Set<String>.from(widget.initialFavorites);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _dialogKeyFocusNode.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  List<String> _getFilteredCategories() {
    ContentType type;
    if (_activeTabIndex == 0) {
      type = ContentType.live;
    } else if (_activeTabIndex == 1) {
      type = ContentType.movie;
    } else {
      type = ContentType.series;
    }

    final list = widget.categoriesByType[type] ?? [];
    if (_searchQuery.isEmpty) return list;
    return list.where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _ensureVisible(int index) {
    if (!_listScrollController.hasClients) return;
    const itemHeight = 60.0;
    final targetOffset = (index * itemHeight) - 100.0;
    final clamped = targetOffset.clamp(0.0, _listScrollController.position.maxScrollExtent);
    _listScrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  Future<void> _toggleFavorite(String category) async {
    final isFav = await PreferencesService.toggleFavoriteCategory(category);
    setState(() {
      if (isFav) {
        _currentFavorites.add(category);
      } else {
        _currentFavorites.remove(category);
      }
    });
    widget.onFavoritesChanged(_currentFavorites);
  }

  void _handleDialogKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return;
    }

    final items = _getFilteredCategories();

    // When search field has focus
    if (_searchFocusNode.hasFocus) {
      if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        _searchFocusNode.unfocus();
        _dialogKeyFocusNode.requestFocus();
        setState(() {
          if (items.isNotEmpty) {
            _focusArea = _AddMoreFocusArea.listRow;
            _focusedRowIndex = 0;
          } else {
            _focusArea = _AddMoreFocusArea.tabs;
          }
        });
      } else if (key == LogicalKeyboardKey.arrowUp) {
        _searchFocusNode.unfocus();
        _dialogKeyFocusNode.requestFocus();
        setState(() {
          _focusArea = _AddMoreFocusArea.closeButton;
        });
      }
      return;
    }

    // Modal navigation using D-pad / Arrow keys
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_focusArea == _AddMoreFocusArea.listRow || _focusArea == _AddMoreFocusArea.listHeart) {
        if (_focusedRowIndex > 0) {
          setState(() {
            _focusedRowIndex--;
          });
          _ensureVisible(_focusedRowIndex);
        } else {
          setState(() {
            _focusArea = _AddMoreFocusArea.tabs;
          });
        }
      } else if (_focusArea == _AddMoreFocusArea.tabs) {
        _dialogKeyFocusNode.unfocus();
        _searchFocusNode.requestFocus();
        setState(() {
          _focusArea = _AddMoreFocusArea.search;
        });
      } else if (_focusArea == _AddMoreFocusArea.search) {
        setState(() {
          _focusArea = _AddMoreFocusArea.closeButton;
        });
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (_focusArea == _AddMoreFocusArea.closeButton) {
        _searchFocusNode.requestFocus();
        setState(() {
          _focusArea = _AddMoreFocusArea.search;
        });
      } else if (_focusArea == _AddMoreFocusArea.search) {
        _searchFocusNode.unfocus();
        _dialogKeyFocusNode.requestFocus();
        setState(() {
          _focusArea = _AddMoreFocusArea.tabs;
        });
      } else if (_focusArea == _AddMoreFocusArea.tabs) {
        if (items.isNotEmpty) {
          setState(() {
            _focusArea = _AddMoreFocusArea.listRow;
            _focusedRowIndex = 0;
          });
          _ensureVisible(0);
        }
      } else if (_focusArea == _AddMoreFocusArea.listRow || _focusArea == _AddMoreFocusArea.listHeart) {
        if (_focusedRowIndex < items.length - 1) {
          setState(() {
            _focusedRowIndex++;
          });
          _ensureVisible(_focusedRowIndex);
        }
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (_focusArea == _AddMoreFocusArea.tabs) {
        if (_activeTabIndex > 0) {
          setState(() {
            _activeTabIndex--;
            _focusedRowIndex = 0;
          });
        }
      } else if (_focusArea == _AddMoreFocusArea.listHeart) {
        setState(() {
          _focusArea = _AddMoreFocusArea.listRow;
        });
      }
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (_focusArea == _AddMoreFocusArea.tabs) {
        if (_activeTabIndex < 2) {
          setState(() {
            _activeTabIndex++;
            _focusedRowIndex = 0;
          });
        }
      } else if (_focusArea == _AddMoreFocusArea.listRow) {
        setState(() {
          _focusArea = _AddMoreFocusArea.listHeart;
        });
      }
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space) {
      if (_focusArea == _AddMoreFocusArea.closeButton) {
        Navigator.pop(context);
      } else if (_focusArea == _AddMoreFocusArea.search) {
        _searchFocusNode.requestFocus();
      } else if (_focusArea == _AddMoreFocusArea.tabs) {
        if (items.isNotEmpty) {
          setState(() {
            _focusArea = _AddMoreFocusArea.listRow;
            _focusedRowIndex = 0;
          });
        }
      } else if (_focusArea == _AddMoreFocusArea.listRow || _focusArea == _AddMoreFocusArea.listHeart) {
        if (_focusedRowIndex >= 0 && _focusedRowIndex < items.length) {
          _toggleFavorite(items[_focusedRowIndex]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getFilteredCategories();
    final selectedCount = _currentFavorites.length;

    return KeyboardListener(
      focusNode: _dialogKeyFocusNode,
      autofocus: true,
      onKeyEvent: _handleDialogKeyEvent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: const Color(0xFF171719),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2B2B30), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 36,
                  spreadRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  children: [
                    // Plus Badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3F3F46).withValues(alpha: 0.6)),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, color: Color(0xFFE4E4E7), size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add to VortexTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Selected Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '$selectedCount Selected',
                        style: const TextStyle(
                          color: Color(0xFF22D3EE),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Close Button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _focusArea == _AddMoreFocusArea.closeButton
                              ? const Color(0xFF27272A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _focusArea == _AddMoreFocusArea.closeButton
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFA1A1AA), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Favorite categories from your playlist to automatically populate your personalized shelves.',
                  style: TextStyle(color: Color(0xFF8E8E97), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Search Bar Input Field
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? Colors.white
                          : (_focusArea == _AddMoreFocusArea.search
                              ? Colors.white70
                              : const Color(0xFF2B2B30)),
                      width: _searchFocusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF757580), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: const InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: TextStyle(color: Color(0xFF787882), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                              _focusedRowIndex = 0;
                            });
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _focusedRowIndex = 0;
                            });
                          },
                          child: const Icon(Icons.clear, color: Color(0xFF787882), size: 16),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tab Navigation Bar: Live TV | Movies / VOD | Series
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121214),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Live TV'),
                      _buildTabButton(1, 'Movies / VOD'),
                      _buildTabButton(2, 'Series'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Category Items List
                Expanded(
                  child: filteredCategories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              _searchQuery.isEmpty ? 'No categories available' : 'No categories found matching "$_searchQuery"',
                              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _listScrollController,
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final cat = filteredCategories[index];
                            final isFav = _currentFavorites.contains(cat);
                            final isRowFocused = (_focusArea == _AddMoreFocusArea.listRow) && (_focusedRowIndex == index);
                            final isHeartFocused = (_focusArea == _AddMoreFocusArea.listHeart) && (_focusedRowIndex == index);

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: InkWell(
                                onTap: () => _toggleFavorite(cat),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isRowFocused
                                        ? const Color(0xFF27272C)
                                        : (isFav ? const Color(0xFF1E1E21) : const Color(0xFF1E1E21)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isRowFocused
                                          ? (isFav ? const Color(0xFFE50914) : Colors.white)
                                          : (isFav ? const Color(0xFFE50914).withValues(alpha: 0.4) : const Color(0xFF26262A)),
                                      width: isRowFocused ? 2 : 1,
                                    ),
                                    boxShadow: isRowFocused
                                        ? [
                                            BoxShadow(
                                              color: (isFav ? const Color(0xFFE50914) : Colors.white).withValues(alpha: 0.2),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            color: isFav ? Colors.white : const Color(0xFFD4D4D8),
                                            fontWeight: isFav || isRowFocused ? FontWeight.w600 : FontWeight.w500,
                                            fontSize: 14,
                                            letterSpacing: 0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Heart Toggle Button
                                      GestureDetector(
                                        onTap: () => _toggleFavorite(cat),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isHeartFocused ? const Color(0xFF333338) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: isHeartFocused
                                                ? Border.all(
                                                    color: isFav ? const Color(0xFFE50914) : Colors.white,
                                                    width: 2,
                                                  )
                                                : null,
                                          ),
                                          child: Icon(
                                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: isFav ? const Color(0xFFE50914) : const Color(0xFF71717A),
                                            size: 20,
                                          ),
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
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isActive = _activeTabIndex == index;
    final isFocused = _focusArea == _AddMoreFocusArea.tabs && _activeTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
            _focusArea = _AddMoreFocusArea.tabs;
            _focusedRowIndex = 0;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF252529) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused ? Colors.white : (isActive ? Colors.white70 : Colors.transparent),
              width: isFocused ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFFA1A1AA),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

enum VortexZone { sidebar, searchBar, filterBar, content }

enum VortexFilterType { all, recent, topRated, inProgress, category }

class VortexActiveFilter {
  final VortexFilterType type;
  final String? categoryName;

  const VortexActiveFilter._(this.type, [this.categoryName]);

  static const all = VortexActiveFilter._(VortexFilterType.all);
  static const recent = VortexActiveFilter._(VortexFilterType.recent);
  static const topRated = VortexActiveFilter._(VortexFilterType.topRated);
  static const inProgress = VortexActiveFilter._(VortexFilterType.inProgress);
  static VortexActiveFilter category(String name) => VortexActiveFilter._(VortexFilterType.category, name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VortexActiveFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          categoryName == other.categoryName;

  @override
  int get hashCode => type.hashCode ^ categoryName.hashCode;
}

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
  List<Channel> _filteredScopedItems = [];
  Set<String> _favoriteCategories = {};
  Playlist? _activePlaylist;
  bool _isLoading = true;

  // Filter State - Strictly SINGLE active filter at a time
  VortexActiveFilter _activeFilter = VortexActiveFilter.all;
  int _focusedFilterIndex = 0;

  // Infinite Scroll & Pagination
  int _displayedCount = 36;
  final int _pageSize = 24;

  // Search State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();

  // Scroll Controllers
  final ScrollController _mainScrollController = ScrollController();
  final Map<int, ScrollController> _shelfScrollControllers = {};
  final ScrollController _filterBarScrollController = ScrollController();

  // Focus indices in content zone
  int _focusedShelfIndex = 0;
  int _focusedItemIndex = 0;
  int _focusedGridIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {'target': VortexNavTarget.search, 'icon': Icons.search_rounded, 'label': 'Search'},
    {'target': VortexNavTarget.home, 'icon': Icons.home_rounded, 'label': 'Home'},
    {'target': VortexNavTarget.movies, 'icon': Icons.movie_outlined, 'label': 'Movies'},
    {'target': VortexNavTarget.liveTv, 'icon': Icons.live_tv_rounded, 'label': 'Live TV'},
    {'target': VortexNavTarget.series, 'icon': Icons.video_collection_outlined, 'label': 'Series'},
    {'target': VortexNavTarget.addMore, 'icon': Icons.add_circle_outline_rounded, 'label': 'Add More'},
    {'target': VortexNavTarget.goToHome, 'icon': Icons.logout_rounded, 'label': 'Go To Home'},
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
    _filterBarScrollController.dispose();
    for (final c in _shelfScrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_mainScrollController.hasClients &&
        _mainScrollController.position.pixels >= _mainScrollController.position.maxScrollExtent - 300) {
      if (_displayedCount < _filteredScopedItems.length) {
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
      final shelves = await VortexTubeService.getPersonalizedFeed(searchQuery: _searchQuery);
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

      _scopedItems = filtered;
      _applyFilter();

      if (mounted) {
        setState(() {
          _displayedCount = _pageSize;
          _isLoading = false;
          _focusedGridIndex = 0;
        });
      }
    }
  }

  void _applyFilter() {
    var items = List<Channel>.from(_scopedItems);

    switch (_activeFilter.type) {
      case VortexFilterType.all:
        break;
      case VortexFilterType.recent:
        items = items.where((c) => c.lastPlayed != null).toList()
          ..sort((a, b) => (b.lastPlayed ?? DateTime(2000)).compareTo(a.lastPlayed ?? DateTime(2000)));
        break;
      case VortexFilterType.topRated:
        items = items.where((c) => c.rating >= 6.0).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
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

    if (_activeFilter.type != VortexFilterType.recent && _activeFilter.type != VortexFilterType.topRated) {
      items.sort((a, b) => VortexTubeService.scoreItem(channel: b, lovedCategories: _favoriteCategories)
          .compareTo(VortexTubeService.scoreItem(channel: a, lovedCategories: _favoriteCategories)));
    }

    _filteredScopedItems = items;
  }

  List<String> _getAvailableCategoryFilters() {
    final set = <String>{'All'};
    for (final item in _scopedItems) {
      if (item.group != null && item.group!.isNotEmpty) {
        set.add(item.group!);
      }
    }
    return set.toList();
  }

  void _showAddMorePopup() async {
    final allChannels = await DatabaseService.getAllChannels();
    final categoriesByType = <ContentType, List<String>>{
      ContentType.live: [],
      ContentType.movie: [],
      ContentType.series: [],
    };

    final liveSet = <String>{};
    final movieSet = <String>{};
    final seriesSet = <String>{};

    for (final c in allChannels) {
      if (c.group != null && c.group!.isNotEmpty) {
        if (c.contentType == ContentType.live) liveSet.add(c.group!);
        if (c.contentType == ContentType.movie) movieSet.add(c.group!);
        if (c.contentType == ContentType.series) seriesSet.add(c.group!);
      }
    }

    categoriesByType[ContentType.live] = liveSet.toList()..sort();
    categoriesByType[ContentType.movie] = movieSet.toList()..sort();
    categoriesByType[ContentType.series] = seriesSet.toList()..sort();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _AddMoreVortexDialog(
          categoriesByType: categoriesByType,
          initialFavorites: _favoriteCategories,
          onFavoritesChanged: (updated) {
            setState(() {
              _favoriteCategories = updated;
            });
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

  void _showVortexSettingsPopup() async {
    final playlists = await DatabaseService.getAllPlaylists();
    final favCategories = (await PreferencesService.getFavoriteCategories()).toList()..sort();

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
                width: 620,
                height: 560,
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
                          child: const Icon(Icons.settings_rounded, color: Color(0xFFFF0000)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'VortexTube Settings & Playlists',
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
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
                      'Manage playlists and favorite lists directly within VortexTube.',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF282828), height: 1),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              indicatorColor: Color(0xFFFF0000),
                              labelColor: Colors.white,
                              unselectedLabelColor: Color(0xFF888888),
                              tabs: [
                                Tab(text: 'Playlists Manager'),
                                Tab(text: 'Loved Categories'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Tab 1: Playlists Manager with Add Button
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final newPl = await showDialog<Playlist>(
                                                context: context,
                                                builder: (context) => const PlaylistDialog(),
                                              );
                                              if (newPl != null) {
                                                await DatabaseService.addPlaylist(newPl);
                                                await PreferencesService.setActivePlaylistId(newPl.id);
                                                final updated = await DatabaseService.getAllPlaylists();
                                                setDialogState(() {
                                                  playlists.clear();
                                                  playlists.addAll(updated);
                                                  _activePlaylist = newPl;
                                                });
                                                setState(() {
                                                  _activePlaylist = newPl;
                                                });
                                                _loadInitialData();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF0000),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            icon: const Icon(Icons.add_rounded, size: 20),
                                            label: const Text(
                                              'Add Playlist (M3U, Xtream, Stalker/MAG)',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: playlists.length,
                                    itemBuilder: (context, index) {
                                      final pl = playlists[index];
                                      final isActive = pl.id == _activePlaylist?.id;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFF242424) : const Color(0xFF1B1B1B),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isActive ? const Color(0xFFFF0000) : const Color(0xFF2A2A2A),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              pl.isStalker
                                                  ? Icons.router_rounded
                                                  : pl.isXtreamCodes
                                                      ? Icons.dns_rounded
                                                      : Icons.playlist_play_rounded,
                                              color: isActive ? const Color(0xFFFF0000) : Colors.white70,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pl.name,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(
                                                    '${pl.channelCount} items',
                                                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!isActive)
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await PreferencesService.setActivePlaylistId(pl.id);
                                                  setDialogState(() {
                                                    _activePlaylist = pl;
                                                  });
                                                  setState(() {
                                                    _activePlaylist = pl;
                                                  });
                                                  _loadInitialData();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2A2A2A),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: const Text('Use', style: TextStyle(fontSize: 12)),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF0000).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'ACTIVE',
                                                  style: TextStyle(color: Color(0xFFFF0000), fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                              onPressed: () async {
                                                await DatabaseService.deletePlaylist(pl.id);
                                                final updated = await DatabaseService.getAllPlaylists();
                                                setDialogState(() {
                                                  playlists.clear();
                                                  playlists.addAll(updated);
                                                  if (_activePlaylist?.id == pl.id) {
                                                    _activePlaylist = updated.firstOrNull;
                                                  }
                                                });
                                                setState(() {
                                                  _activePlaylist = playlists.firstOrNull;
                                                });
                                                _loadInitialData();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                      ),
                                    ],
                                  ),

                                  // Tab 2: Loved Categories Manager
                                  ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: favCategories.length,
                                    itemBuilder: (context, index) {
                                      final cat = favCategories[index];
                                      return FocusableActionDetector(
                                        actions: {
                                          ActivateIntent: CallbackAction<ActivateIntent>(
                                            onInvoke: (_) async {
                                              await PreferencesService.toggleFavoriteCategory(cat);
                                              setDialogState(() {
                                                favCategories.remove(cat);
                                                _favoriteCategories.remove(cat);
                                              });
                                              setState(() {});
                                              return null;
                                            },
                                          ),
                                        },
                                        child: Builder(
                                          builder: (context) {
                                            final hasFocus = Focus.of(context).hasFocus;
                                            return InkWell(
                                              onTap: () async {
                                                await PreferencesService.toggleFavoriteCategory(cat);
                                                setDialogState(() {
                                                  favCategories.remove(cat);
                                                  _favoriteCategories.remove(cat);
                                                });
                                                setState(() {});
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: hasFocus ? const Color(0xFF333333) : const Color(0xFF1E1E1E),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: hasFocus ? Colors.white : Colors.transparent,
                                                    width: hasFocus ? 2 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.favorite_rounded, color: Color(0xFFFF0000), size: 18),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        cat,
                                                        style: TextStyle(
                                                          color: hasFocus ? Colors.white : const Color(0xFFE0E0E0),
                                                          fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    const Icon(Icons.remove_circle_outline, color: Color(0xFF888888), size: 18),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
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

    _loadInitialData();
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
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.select) {
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

  int _getColumnCount() {
    if (_activeNav == VortexNavTarget.liveTv) {
      return 10; // 10 items in one row for Live TV circular channel badges
    }
    return 6; // 6 items in one row for Movies & Series posters
  }

  void _moveUp() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          // Search is the top-most item of sidebar (index 0). Cannot go above search!
          if (_focusedNavIndex > 0) {
            _focusedNavIndex--;
          }
          break;
        case VortexZone.searchBar:
          // Top boundary: search is already the top-most bar. Do not go above search box!
          break;
        case VortexZone.filterBar:
          _currentZone = VortexZone.searchBar;
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedShelfIndex > 0) {
              _focusedShelfIndex--;
              _focusedItemIndex = 0;
              _ensureVisibleShelf(_focusedShelfIndex);
            } else {
              _currentZone = VortexZone.filterBar;
            }
          } else {
            final cols = _getColumnCount();
            if (_focusedGridIndex >= cols) {
              _focusedGridIndex -= cols;
              _ensureVisibleGridItem(_focusedGridIndex);
            } else {
              _currentZone = VortexZone.filterBar;
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
          _currentZone = VortexZone.filterBar;
          break;
        case VortexZone.filterBar:
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
              _ensureVisibleShelf(_focusedShelfIndex);
            }
          } else {
            final cols = _getColumnCount();
            if (_focusedGridIndex + cols < _filteredScopedItems.length) {
              _focusedGridIndex += cols;
              _ensureVisibleGridItem(_focusedGridIndex);
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
        case VortexZone.filterBar:
          if (_focusedFilterIndex > 0) {
            _focusedFilterIndex--;
            _ensureVisibleFilter(_focusedFilterIndex);
          } else {
            _currentZone = VortexZone.sidebar;
          }
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedItemIndex > 0) {
              _focusedItemIndex--;
              _ensureVisibleShelfItem(_focusedShelfIndex, _focusedItemIndex);
            } else {
              _currentZone = VortexZone.sidebar;
            }
          } else {
            final cols = _getColumnCount();
            if (_focusedGridIndex % cols != 0) {
              _focusedGridIndex--;
              _ensureVisibleGridItem(_focusedGridIndex);
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
          _currentZone = VortexZone.filterBar;
          break;
        case VortexZone.filterBar:
          final filterCount = 4 + _getAvailableCategoryFilters().length;
          if (_focusedFilterIndex < filterCount - 1) {
            _focusedFilterIndex++;
            _ensureVisibleFilter(_focusedFilterIndex);
          }
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedShelfIndex < _shelves.length) {
              final shelf = _shelves[_focusedShelfIndex];
              if (_focusedItemIndex < shelf.items.length - 1) {
                _focusedItemIndex++;
                _ensureVisibleShelfItem(_focusedShelfIndex, _focusedItemIndex);
              }
            }
          } else {
            final cols = _getColumnCount();
            if (_focusedGridIndex < _filteredScopedItems.length - 1 && (_focusedGridIndex + 1) % cols != 0) {
              _focusedGridIndex++;
              _ensureVisibleGridItem(_focusedGridIndex);
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
        break;
      case VortexZone.filterBar:
        _applyFocusedFilter();
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
          if (_focusedGridIndex < _filteredScopedItems.length) {
            _playItem(_filteredScopedItems[_focusedGridIndex]);
          }
        }
        break;
    }
  }

  void _applyFocusedFilter() {
    final catFilters = _getAvailableCategoryFilters().where((c) => c != 'All').toList();
    if (_focusedFilterIndex == 0) {
      setState(() {
        _activeFilter = VortexActiveFilter.all;
        _applyFilter();
      });
    } else if (_focusedFilterIndex == 1) {
      setState(() {
        _activeFilter = VortexActiveFilter.recent;
        _applyFilter();
      });
    } else if (_focusedFilterIndex == 2) {
      setState(() {
        _activeFilter = VortexActiveFilter.topRated;
        _applyFilter();
      });
    } else if (_focusedFilterIndex == 3) {
      setState(() {
        _activeFilter = VortexActiveFilter.inProgress;
        _applyFilter();
      });
    } else {
      final catIdx = _focusedFilterIndex - 4;
      if (catIdx >= 0 && catIdx < catFilters.length) {
        setState(() {
          _activeFilter = VortexActiveFilter.category(catFilters[catIdx]);
          _applyFilter();
        });
      }
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
      _showVortexSettingsPopup();
      return;
    }

    if (target == VortexNavTarget.search) {
      setState(() {
        _currentZone = VortexZone.searchBar;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
      return;
    }

    setState(() {
      _activeNav = target;
      _isLoading = true;
    });
    _loadActiveViewContent();
  }

  void _playItem(Channel item) {
    // For Series, open SeriesDetailScreen where users can choose seasons & episodes
    if (item.contentType == ContentType.series) {
      final series = Series(
        id: item.tvgId?.toString() ?? item.url.replaceAll('stalker://series/', '').replaceAll('xtream://series/', ''),
        playlistId: item.playlistId ?? _activePlaylist?.id,
        name: SeriesParser.groupIntoSeries([item]).values.firstOrNull?.name ?? item.name,
        group: item.group ?? 'Series',
        logo: item.logo,
        poster: item.logo,
        rating: item.rating,
        seasons: [],
      );

      Navigator.push(
        context,
        SmoothPageRoute(child: SeriesDetailScreen(series: series)),
      ).then((_) => _loadActiveViewContent());
      return;
    }

    // For Live TV & Movies, launch player
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Platform.isAndroid
            ? MobileVideoPlayerScreen(channel: item)
            : VideoPlayerScreen(channel: item),
      ),
    ).then((_) => _loadActiveViewContent());
  }

  /// Scrolling with smooth center alignment
  void _ensureVisibleShelf(int shelfIndex) {
    if (!_mainScrollController.hasClients) return;
    const double shelfHeight = 260.0;
    final double viewportHeight = _mainScrollController.position.viewportDimension;
    final double targetOffset = (shelfIndex * shelfHeight) - (viewportHeight / 3);
    final double clampedOffset = targetOffset.clamp(0.0, _mainScrollController.position.maxScrollExtent);

    _mainScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _ensureVisibleShelfItem(int shelfIndex, int itemIndex) {
    final controller = _shelfScrollControllers[shelfIndex];
    if (controller == null || !controller.hasClients) return;

    final isCircular = _shelves[shelfIndex].isCircular;
    final double itemWidth = isCircular ? 110.0 : 220.0;
    final double viewportWidth = controller.position.viewportDimension;
    final double targetOffset = (itemIndex * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);
    final double clampedOffset = targetOffset.clamp(0.0, controller.position.maxScrollExtent);

    controller.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _ensureVisibleGridItem(int gridIndex) {
    if (!_mainScrollController.hasClients) return;
    final cols = _getColumnCount();
    final row = gridIndex ~/ cols;
    final double rowHeight = _activeNav == VortexNavTarget.liveTv ? 130.0 : 250.0;
    final double viewportHeight = _mainScrollController.position.viewportDimension;
    final double targetOffset = (row * rowHeight) - (viewportHeight / 2) + (rowHeight / 2);
    final double clampedOffset = targetOffset.clamp(0.0, _mainScrollController.position.maxScrollExtent);

    _mainScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _ensureVisibleFilter(int filterIndex) {
    if (!_filterBarScrollController.hasClients) return;
    const double filterWidth = 110.0;
    final double targetOffset = (filterIndex * filterWidth) - 100.0;
    final double clampedOffset = targetOffset.clamp(0.0, _filterBarScrollController.position.maxScrollExtent);

    _filterBarScrollController.animateTo(
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
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF0000)))
                          : _activeNav == VortexNavTarget.home
                              ? (_shelves.isEmpty ? _buildEmptyState() : _buildShelvesList())
                              : (_filteredScopedItems.isEmpty ? _buildEmptyScopedState() : _buildScopedGridView()),
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
          // VortexTube Logo & Title directly above Playlist Name
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
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
          ),

          // Profile / Playlist Name info banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.account_circle_rounded, color: Color(0xFFAAAAAA), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activePlaylist?.name ?? 'My Playlist',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Main Navigation Items starting with Search at index 0 (Top-most)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarButton(VortexNavTarget.search, Icons.search_rounded, 'Search', 0),
                _buildSidebarButton(VortexNavTarget.home, Icons.home_rounded, 'Home', 1),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFF222222), height: 1),
                ),
                _buildSidebarButton(VortexNavTarget.movies, Icons.movie_outlined, 'Movies', 2),
                _buildSidebarButton(VortexNavTarget.liveTv, Icons.live_tv_rounded, 'Live TV', 3),
                _buildSidebarButton(VortexNavTarget.series, Icons.video_collection_outlined, 'Series', 4),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFF222222), height: 1),
                ),
                _buildSidebarButton(VortexNavTarget.addMore, Icons.add_circle_outline_rounded, 'Add More', 5),
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
                _buildSidebarButton(VortexNavTarget.goToHome, Icons.logout_rounded, 'Go To Home', 6),
                _buildSidebarButton(VortexNavTarget.settings, Icons.settings_outlined, 'Settings', 7),
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
    final isSearchFocused = _currentZone == VortexZone.searchBar;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
      ),
      child: Row(
        children: [
          // Search Capsule
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSearchFocused ? Colors.white : Colors.transparent,
                width: isSearchFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded, color: Color(0xFFAAAAAA), size: 18),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    textInputAction: TextInputAction.search,
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
                    onSubmitted: (val) {
                      _searchFocusNode.unfocus();
                      _screenFocusNode.requestFocus();
                      setState(() {
                        _searchQuery = val;
                        _currentZone = VortexZone.content;
                      });
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
                      child: Icon(Icons.clear, color: Color(0xFF888888), size: 16),
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
    // DO NOT show filter bar on Home tab
    if (_activeNav == VortexNavTarget.home) {
      return const SizedBox.shrink();
    }

    final catFilters = _getAvailableCategoryFilters().where((c) => c != 'All').toList();
    final isLiveTv = _activeNav == VortexNavTarget.liveTv;

    final filterPills = <Widget>[
      _buildFilterPill('All', _activeFilter == VortexActiveFilter.all, 0, () {
        setState(() {
          _activeFilter = VortexActiveFilter.all;
          _applyFilter();
        });
      }),
      // In Live TV tab, only show All and Category filters (no top rated or in progress)
      if (!isLiveTv) ...[
        _buildFilterPill('Recently Watched', _activeFilter == VortexActiveFilter.recent, 1, () {
          setState(() {
            _activeFilter = VortexActiveFilter.recent;
            _applyFilter();
          });
        }),
        _buildFilterPill('Top Rated', _activeFilter == VortexActiveFilter.topRated, 2, () {
          setState(() {
            _activeFilter = VortexActiveFilter.topRated;
            _applyFilter();
          });
        }),
        _buildFilterPill('In Progress', _activeFilter == VortexActiveFilter.inProgress, 3, () {
          setState(() {
            _activeFilter = VortexActiveFilter.inProgress;
            _applyFilter();
          });
        }),
      ],
    ];

    final offset = isLiveTv ? 1 : 4;
    for (int i = 0; i < catFilters.length; i++) {
      final cat = catFilters[i];
      final targetFilter = VortexActiveFilter.category(cat);
      final idx = offset + i;
      filterPills.add(
        _buildFilterPill(cat, _activeFilter == targetFilter, idx, () {
          setState(() {
            _activeFilter = targetFilter;
            _applyFilter();
          });
        }),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6), // Balanced equal top and bottom padding
      alignment: Alignment.centerLeft,
      child: ListView(
        controller: _filterBarScrollController,
        scrollDirection: Axis.horizontal,
        children: filterPills,
      ),
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, int filterIndex, VoidCallback onTap) {
    final isFocused = _currentZone == VortexZone.filterBar && _focusedFilterIndex == filterIndex;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentZone = VortexZone.filterBar;
            _focusedFilterIndex = filterIndex;
          });
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF1F1F1)
                : isFocused
                    ? const Color(0xFF3F3F3F)
                    : const Color(0xFF272727),
            borderRadius: BorderRadius.circular(16),
            border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : const Color(0xFFF1F1F1),
              fontSize: 12.5,
              fontWeight: isSelected || isFocused ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            height: shelf.isCircular ? 130 : 260, // Exactly sized to match Movies/Series tab 2:3 card height
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
                    : _buildPosterCard(item, isFocused, shelfIndex, itemIndex);
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
        width: 95,
        margin: const EdgeInsets.only(right: 16),
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
                          color: Colors.white.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: item.logo != null && item.logo!.isNotEmpty
                    ? Image.network(
                        item.logo!,
                        fit: BoxFit.contain, // Fixed: logo properly contained
                        errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white70, size: 26),
                      )
                    : const Icon(Icons.tv, color: Colors.white70, size: 26),
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

  Widget _buildPosterCard(Channel item, bool isFocused, int shelfIndex, int itemIndex) {
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
        width: 175, // Exact same size as Movies/Series tab cards
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
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 18,
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
                            height: double.infinity,
                            fit: BoxFit.cover, // Same perfect poster cover as movies/series tab
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.group ?? 'Loved',
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.rating > 0) ...[
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
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
    final displayedItems = _filteredScopedItems.take(_displayedCount).toList();
    final isLive = _activeNav == VortexNavTarget.liveTv;

    if (isLive) {
      // 10-11 circular items in one row scrolling down until channel list ends
      return GridView.builder(
        controller: _mainScrollController,
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
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
                              color: Colors.white.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: ClipOval(
                    child: item.logo != null && item.logo!.isNotEmpty
                        ? Image.network(
                            item.logo!,
                            fit: BoxFit.contain, // Fixed: logo properly contained
                            errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white70, size: 26),
                          )
                        : const Icon(Icons.tv, color: Colors.white70, size: 26),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  style: TextStyle(
                    color: isFocused ? Colors.white : const Color(0xFFAAAAAA),
                    fontSize: 11,
                    fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

    // Movies and Series Professional Grid (6 vertical poster cards per row)
    return GridView.builder(
      controller: _mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 0.68,
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
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 18,
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
                                height: double.infinity,
                                fit: BoxFit.cover, // Professional poster cover
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.group ?? 'Loved',
                              style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.rating > 0) ...[
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
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
