import 'dart:async';
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

import 'home/vortex_home_view.dart';
import 'live/vortex_live_view.dart';
import 'movies/vortex_movies_view.dart';
import 'player/mobile_video_player_screen.dart';
import 'player/video_player_screen.dart';
import 'search/vortex_search_bar.dart';
import 'series/series_detail_screen.dart';
import 'series/vortex_series_view.dart';
import 'settings/vortex_settings_view.dart';
import 'sidebar/vortex_nav_types.dart';
import 'sidebar/vortex_sidebar.dart';

export 'sidebar/vortex_nav_types.dart';

class VortexTubeScreen extends StatefulWidget {
  const VortexTubeScreen({super.key});

  @override
  State<VortexTubeScreen> createState() => _VortexTubeScreenState();
}

class _VortexTubeScreenState extends State<VortexTubeScreen> {
  // Navigation & View State
  VortexNavTarget _activeNav = VortexNavTarget.home;
  VortexZone _currentZone = VortexZone.content;
  int _focusedNavIndex = 1; // Home is index 1

  // Sidebar Collapsible State
  bool _isSidebarExpanded = true;
  bool _isSidebarHovered = false;
  Timer? _sidebarCollapseTimer;
  Timer? _navDebounceTimer;
  Timer? _searchDebounceTimer;

  // Cached full channel list to avoid frequent DB reads
  List<Channel>? _cachedAllChannels;

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

  // Sorting Option for Movies and Series
  VortexSortOption _sortOption = VortexSortOption.recommended;

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
  int _lastFocusedGridIndex = 0;
  final Map<int, GlobalKey> _cardKeys = {};

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
    _sidebarCollapseTimer?.cancel();
    _navDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
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

  void _onSidebarMouseEnter() {
    _sidebarCollapseTimer?.cancel();
    _sidebarCollapseTimer = null;
    setState(() {
      _isSidebarHovered = true;
      _isSidebarExpanded = true;
    });
  }

  void _onSidebarMouseExit() {
    _sidebarCollapseTimer?.cancel();
    _sidebarCollapseTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _isSidebarHovered = false;
          if (_currentZone != VortexZone.sidebar) {
            _isSidebarExpanded = false;
          }
        });
      }
    });
  }

  void _toggleSidebarExpanded() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
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

    _cachedAllChannels = await DatabaseService.getAllChannels();

    await _loadActiveViewContent();
  }

  Future<void> _loadActiveViewContent() async {
    if (_activeNav == VortexNavTarget.settings) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (_activeNav == VortexNavTarget.home) {
      final shelves = await VortexTubeService.getPersonalizedFeed(
        searchQuery: _searchQuery,
        preloadedChannels: _cachedAllChannels,
      );
      if (mounted) {
        setState(() {
          _shelves = shelves;
          _isLoading = false;
          _focusedShelfIndex = 0;
          _focusedItemIndex = 0;
        });
      }
    } else {
      _cachedAllChannels ??= await DatabaseService.getAllChannels();
      final allChannels = _cachedAllChannels!;
      final lovedCategories = _favoriteCategories;

      List<Channel> typeChannels;
      if (_activeNav == VortexNavTarget.liveTv) {
        typeChannels = allChannels.where((c) => c.contentType == ContentType.live).toList();
      } else if (_activeNav == VortexNavTarget.movies) {
        typeChannels = allChannels.where((c) => c.contentType == ContentType.movie).toList();
      } else if (_activeNav == VortexNavTarget.series) {
        typeChannels = allChannels.where((c) => c.contentType == ContentType.series).toList();
      } else {
        typeChannels = allChannels;
      }

      var filtered = typeChannels.where((c) {
        final isItemLoved = c.isFavorite;
        final isCatLoved = c.group != null && lovedCategories.contains(c.group!);
        return isItemLoved || isCatLoved;
      }).toList();

      if (_searchQuery.trim().isNotEmpty) {
        filtered = filtered
            .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }

      filtered.sort((a, b) => VortexTubeService.scoreItem(channel: b, lovedCategories: lovedCategories)
          .compareTo(VortexTubeService.scoreItem(channel: a, lovedCategories: lovedCategories)));

      _scopedItems = filtered;
      _applyFilter();

      _cardKeys.clear();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _focusedGridIndex = 0;
          _lastFocusedGridIndex = 0;
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
      case VortexFilterType.inProgress:
        items = items.where((c) => c.watchedMilliseconds > 0).toList();
        break;
      case VortexFilterType.category:
        if (_activeFilter.categoryName != null) {
          items = items.where((c) => c.group == _activeFilter.categoryName).toList();
        }
        break;
    }

    if (_activeNav == VortexNavTarget.movies || _activeNav == VortexNavTarget.series) {
      switch (_sortOption) {
        case VortexSortOption.recommended:
          if (_activeFilter.type != VortexFilterType.recent) {
            items.sort((a, b) => VortexTubeService.scoreItem(channel: b, lovedCategories: _favoriteCategories)
                .compareTo(VortexTubeService.scoreItem(channel: a, lovedCategories: _favoriteCategories)));
          }
          break;
        case VortexSortOption.nameAsc:
          items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case VortexSortOption.nameDesc:
          items.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case VortexSortOption.releaseDate:
          items.sort((a, b) {
            final aYear = _extractYear(a.name);
            final bYear = _extractYear(b.name);
            if (aYear != bYear) {
              return bYear.compareTo(aYear);
            }
            if (a.lastPlayed != null && b.lastPlayed != null) {
              return b.lastPlayed!.compareTo(a.lastPlayed!);
            }
            return (b.lastPlayed != null ? 1 : 0).compareTo(a.lastPlayed != null ? 1 : 0);
          });
          break;
      }
    } else {
      if (_activeFilter.type != VortexFilterType.recent) {
        items.sort((a, b) => VortexTubeService.scoreItem(channel: b, lovedCategories: _favoriteCategories)
            .compareTo(VortexTubeService.scoreItem(channel: a, lovedCategories: _favoriteCategories)));
      }
    }

    if (_activeFilter.type == VortexFilterType.all) {
      final List<Channel> ordered = [];
      final Set<String> processedCats = {};

      for (final favCat in _favoriteCategories) {
        final catItems = items.where((c) => c.group == favCat).toList();
        if (catItems.isNotEmpty) {
          ordered.addAll(catItems);
          processedCats.add(favCat);
        }
      }
      for (final item in items) {
        final cat = item.group ?? (_activeNav == VortexNavTarget.liveTv ? 'Other Channels' : (_activeNav == VortexNavTarget.movies ? 'Movies' : 'Series'));
        if (!processedCats.contains(cat)) {
          final catItems = items.where((c) => (c.group ?? (_activeNav == VortexNavTarget.liveTv ? 'Other Channels' : (_activeNav == VortexNavTarget.movies ? 'Movies' : 'Series'))) == cat).toList();
          ordered.addAll(catItems);
          processedCats.add(cat);
        }
      }
      items = ordered;
    }

    _filteredScopedItems = items;
  }

  int _extractYear(String text) {
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }

  List<String> _getAvailableCategoryFilters() {
    final set = <String>{'All'};
    for (final item in _scopedItems) {
      if (item.group != null && item.group!.isNotEmpty && _favoriteCategories.contains(item.group!)) {
        set.add(item.group!);
      }
    }
    for (final cat in _favoriteCategories) {
      if (_scopedItems.any((c) => c.group == cat)) {
        set.add(cat);
      }
    }
    final sorted = set.where((c) => c != 'All').toList()..sort();
    return ['All', ...sorted];
  }

  void _clearSearchState() {
    _searchController.clear();
    _searchQuery = '';
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
      if (_currentZone == VortexZone.sidebar) {
        setState(() {
          _isSidebarExpanded = false;
          _currentZone = VortexZone.content;
          _focusedGridIndex = _lastFocusedGridIndex.clamp(0, (_filteredScopedItems.length - 1).clamp(0, 999999));
        });
        _ensureVisibleGridItem(_focusedGridIndex);
        return;
      }
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
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
        setState(() {
          _currentZone = VortexZone.sidebar;
          _focusedNavIndex = 1; // 1 is Home
          _activeNav = VortexNavTarget.home;
          _isSidebarExpanded = true;
        });
        _selectNavTarget(VortexNavTarget.home);
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
      return 10;
    }
    return 6;
  }

  List<int> _getSectionCounts() {
    final Map<String, int> counts = {};
    for (final item in _filteredScopedItems) {
      final cat = item.group ?? (_activeNav == VortexNavTarget.liveTv ? 'Other Channels' : (_activeNav == VortexNavTarget.movies ? 'Movies' : 'Series'));
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts.values.toList();
  }

  (int sectionIndex, int localIndex) _mapGlobalToSection(int globalIdx, List<int> sectionCounts) {
    int running = 0;
    for (int s = 0; s < sectionCounts.length; s++) {
      final count = sectionCounts[s];
      if (globalIdx < running + count) {
        return (s, globalIdx - running);
      }
      running += count;
    }
    return (0, 0);
  }

  int _mapSectionToGlobal(int sectionIdx, int localIdx, List<int> sectionCounts) {
    int running = 0;
    for (int s = 0; s < sectionIdx && s < sectionCounts.length; s++) {
      running += sectionCounts[s];
    }
    return running + localIdx;
  }

  void _moveUp() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          if (_focusedNavIndex > 0) {
            _focusedNavIndex--;
            final nav = _navItems[_focusedNavIndex]['target'] as VortexNavTarget;
            _selectNavTarget(nav);
          }
          break;
        case VortexZone.searchBar:
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
            final sectionCounts = _getSectionCounts();
            if (sectionCounts.isEmpty) return;

            final (secIdx, localIdx) = _mapGlobalToSection(_focusedGridIndex, sectionCounts);
            final row = localIdx ~/ cols;
            final col = localIdx % cols;

            if (row > 0) {
              final targetLocal = (row - 1) * cols + col;
              _focusedGridIndex = _mapSectionToGlobal(secIdx, targetLocal, sectionCounts);
              _lastFocusedGridIndex = _focusedGridIndex;
              _ensureVisibleGridItem(_focusedGridIndex);
            } else {
              if (secIdx > 0) {
                final prevSecCount = sectionCounts[secIdx - 1];
                final prevLastRow = (prevSecCount - 1) ~/ cols;
                final targetLocal = ((prevLastRow * cols) + col).clamp(0, prevSecCount - 1);
                _focusedGridIndex = _mapSectionToGlobal(secIdx - 1, targetLocal, sectionCounts);
                _lastFocusedGridIndex = _focusedGridIndex;
                _ensureVisibleGridItem(_focusedGridIndex);
              } else {
                _currentZone = VortexZone.filterBar;
              }
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
            final nav = _navItems[_focusedNavIndex]['target'] as VortexNavTarget;
            _selectNavTarget(nav);
          }
          break;
        case VortexZone.searchBar:
          _currentZone = VortexZone.filterBar;
          break;
        case VortexZone.filterBar:
          _currentZone = VortexZone.content;
          _focusedShelfIndex = 0;
          _focusedItemIndex = 0;
          _focusedGridIndex = _lastFocusedGridIndex.clamp(0, (_filteredScopedItems.length - 1).clamp(0, 999999));
          _ensureVisibleGridItem(_focusedGridIndex);
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
            final sectionCounts = _getSectionCounts();
            if (sectionCounts.isEmpty) return;

            final (secIdx, localIdx) = _mapGlobalToSection(_focusedGridIndex, sectionCounts);
            final currentSecCount = sectionCounts[secIdx];
            final row = localIdx ~/ cols;
            final col = localIdx % cols;
            final lastRowInSec = (currentSecCount - 1) ~/ cols;

            if (row < lastRowInSec) {
              final targetLocal = ((row + 1) * cols + col).clamp(0, currentSecCount - 1);
              _focusedGridIndex = _mapSectionToGlobal(secIdx, targetLocal, sectionCounts);
              _lastFocusedGridIndex = _focusedGridIndex;
              _ensureVisibleGridItem(_focusedGridIndex);
            } else {
              if (secIdx < sectionCounts.length - 1) {
                final nextSecCount = sectionCounts[secIdx + 1];
                final targetLocal = col.clamp(0, nextSecCount - 1);
                _focusedGridIndex = _mapSectionToGlobal(secIdx + 1, targetLocal, sectionCounts);
                _lastFocusedGridIndex = _focusedGridIndex;
                _ensureVisibleGridItem(_focusedGridIndex);
              }
            }
          }
          break;
      }
    });
  }

  void _focusSidebar() {
    _currentZone = VortexZone.sidebar;
    _isSidebarExpanded = true;
    final activeIndex = _navItems.indexWhere((item) => item['target'] == _activeNav);
    if (activeIndex != -1) {
      _focusedNavIndex = activeIndex;
    }
    final nav = _navItems[_focusedNavIndex]['target'] as VortexNavTarget;
    _selectNavTarget(nav);
  }

  void _moveLeft() {
    setState(() {
      switch (_currentZone) {
        case VortexZone.sidebar:
          break;
        case VortexZone.searchBar:
          _focusSidebar();
          break;
        case VortexZone.filterBar:
          if (_focusedFilterIndex > 0) {
            _focusedFilterIndex--;
            _ensureVisibleFilter(_focusedFilterIndex);
          } else {
            _focusSidebar();
          }
          break;
        case VortexZone.content:
          if (_activeNav == VortexNavTarget.home) {
            if (_focusedItemIndex > 0) {
              _focusedItemIndex--;
              _ensureVisibleShelfItem(_focusedShelfIndex, _focusedItemIndex);
            } else {
              _focusSidebar();
            }
          } else {
            final cols = _getColumnCount();
            final sectionCounts = _getSectionCounts();
            if (sectionCounts.isEmpty) return;

            final (secIdx, localIdx) = _mapGlobalToSection(_focusedGridIndex, sectionCounts);
            final col = localIdx % cols;

            if (col > 0) {
              _focusedGridIndex--;
              _lastFocusedGridIndex = _focusedGridIndex;
              _ensureVisibleGridItem(_focusedGridIndex);
            } else {
              _focusSidebar();
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
          if (!_isSidebarHovered) {
            _isSidebarExpanded = false;
          }
          _focusedGridIndex = _lastFocusedGridIndex.clamp(0, (_filteredScopedItems.length - 1).clamp(0, 999999));
          _ensureVisibleGridItem(_focusedGridIndex);
          break;
        case VortexZone.searchBar:
          _currentZone = VortexZone.filterBar;
          break;
        case VortexZone.filterBar:
          final isLiveTv = _activeNav == VortexNavTarget.liveTv;
          final catFilters = _getAvailableCategoryFilters().where((c) => c != 'All').toList();
          final totalFilterCount = (isLiveTv ? 1 : 3) + catFilters.length;
          if (_focusedFilterIndex < totalFilterCount - 1) {
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
            final sectionCounts = _getSectionCounts();
            if (sectionCounts.isEmpty) return;

            final (secIdx, localIdx) = _mapGlobalToSection(_focusedGridIndex, sectionCounts);
            final currentSecCount = sectionCounts[secIdx];
            final col = localIdx % cols;

            if (col < cols - 1 && localIdx < currentSecCount - 1) {
              _focusedGridIndex++;
              _lastFocusedGridIndex = _focusedGridIndex;
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
    final isLiveTv = _activeNav == VortexNavTarget.liveTv;
    final catFilters = _getAvailableCategoryFilters().where((c) => c != 'All').toList();

    if (_focusedFilterIndex == 0) {
      setState(() {
        _activeFilter = VortexActiveFilter.all;
        _applyFilter();
      });
      return;
    }

    if (isLiveTv) {
      final catIdx = _focusedFilterIndex - 1;
      if (catIdx >= 0 && catIdx < catFilters.length) {
        setState(() {
          _activeFilter = VortexActiveFilter.category(catFilters[catIdx]);
          _applyFilter();
        });
      }
    } else {
      if (_focusedFilterIndex == 1) {
        setState(() {
          _activeFilter = VortexActiveFilter.recent;
          _applyFilter();
        });
      } else if (_focusedFilterIndex == 2) {
        setState(() {
          _activeFilter = VortexActiveFilter.inProgress;
          _applyFilter();
        });
      } else {
        final catIdx = _focusedFilterIndex - 3;
        if (catIdx >= 0 && catIdx < catFilters.length) {
          setState(() {
            _activeFilter = VortexActiveFilter.category(catFilters[catIdx]);
            _applyFilter();
          });
        }
      }
    }
  }

  void _cycleSortOption() {
    setState(() {
      switch (_sortOption) {
        case VortexSortOption.recommended:
          _sortOption = VortexSortOption.nameAsc;
          break;
        case VortexSortOption.nameAsc:
          _sortOption = VortexSortOption.nameDesc;
          break;
        case VortexSortOption.nameDesc:
          _sortOption = VortexSortOption.releaseDate;
          break;
        case VortexSortOption.releaseDate:
          _sortOption = VortexSortOption.recommended;
          break;
      }
      _applyFilter();
    });
  }

  void _selectNavTarget(VortexNavTarget target) {
    if (target == VortexNavTarget.settings) {
      _clearSearchState();
      setState(() {
        _activeNav = target;
        _currentZone = VortexZone.content;
        _isLoading = false;
      });
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

    _clearSearchState();

    setState(() {
      _activeNav = target;
      _activeFilter = VortexActiveFilter.all;
      _focusedFilterIndex = 0;
      _isLoading = true;
    });

    _navDebounceTimer?.cancel();
    _navDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadActiveViewContent();
      }
    });
  }

  void _playItem(Channel item) {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Platform.isAndroid
            ? MobileVideoPlayerScreen(channel: item)
            : VideoPlayerScreen(channel: item),
      ),
    ).then((_) => _loadActiveViewContent());
  }

  void _ensureVisibleShelf(int shelfIndex) {
    if (!_mainScrollController.hasClients) return;
    const double shelfHeight = 310.0;
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
    final key = _cardKeys[gridIndex];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
      return;
    }

    if (!_mainScrollController.hasClients) return;
    final sectionCounts = _getSectionCounts();
    if (sectionCounts.isEmpty) return;

    final cols = _getColumnCount();
    final (secIdx, localIdx) = _mapGlobalToSection(gridIndex, sectionCounts);

    double estimatedOffset = 0.0;
    const double headerHeight = 70.0;
    final double rowHeight = _activeNav == VortexNavTarget.liveTv ? 120.0 : 280.0;

    for (int s = 0; s < secIdx; s++) {
      estimatedOffset += headerHeight;
      final secRows = ((sectionCounts[s] - 1) ~/ cols) + 1;
      estimatedOffset += secRows * rowHeight;
    }

    estimatedOffset += headerHeight;
    final currentRowInSec = localIdx ~/ cols;
    estimatedOffset += (currentRowInSec * rowHeight);

    final double viewportHeight = _mainScrollController.position.viewportDimension;
    final double targetOffset = estimatedOffset - (viewportHeight / 2) + (rowHeight / 2);
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
          child: Stack(
            children: [
              Row(
                children: [
                  VortexSidebar(
                    isSidebarExpanded: _isSidebarExpanded,
                    isSidebarHovered: _isSidebarHovered,
                    activeNav: _activeNav,
                    currentZone: _currentZone,
                    focusedNavIndex: _focusedNavIndex,
                    activePlaylist: _activePlaylist,
                    navItems: _navItems,
                    onMouseEnter: _onSidebarMouseEnter,
                    onMouseExit: _onSidebarMouseExit,
                    onSelectNavTarget: _selectNavTarget,
                    onSidebarTap: (idx, target) {
                      setState(() {
                        _currentZone = VortexZone.sidebar;
                        _focusedNavIndex = idx;
                      });
                      _selectNavTarget(target);
                    },
                    onForceRefresh: () {
                      _cachedAllChannels = null;
                      VortexTubeService.invalidateCache();
                      _loadInitialData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feed refreshed!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (_activeNav != VortexNavTarget.settings) ...[
                          VortexSearchBar(
                            searchController: _searchController,
                            searchFocusNode: _searchFocusNode,
                            searchQuery: _searchQuery,
                            currentZone: _currentZone,
                            activeNav: _activeNav,
                            sortOption: _sortOption,
                            isSidebarExpanded: _isSidebarExpanded,
                            onToggleSidebar: _toggleSidebarExpanded,
                            onLeftArrowPressed: () {
                              _searchFocusNode.unfocus();
                              _screenFocusNode.requestFocus();
                              setState(() {
                                _currentZone = VortexZone.sidebar;
                                _focusedNavIndex = 1;
                                _activeNav = VortexNavTarget.home;
                                _isSidebarExpanded = true;
                              });
                              _selectNavTarget(VortexNavTarget.home);
                            },
                            onSearchChanged: (val) {
                              _searchDebounceTimer?.cancel();
                              _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
                                if (mounted) {
                                  setState(() => _searchQuery = val);
                                  _loadActiveViewContent();
                                }
                              });
                            },
                            onSearchSubmitted: (val) {
                              _searchFocusNode.unfocus();
                              _screenFocusNode.requestFocus();
                              setState(() {
                                _searchQuery = val;
                                _currentZone = VortexZone.content;
                              });
                              _loadActiveViewContent();
                            },
                            onClearSearch: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadActiveViewContent();
                            },
                            onCycleSort: _cycleSortOption,
                          ),
                          _buildTopFilterBar(),
                        ],
                        Expanded(
                          child: _isLoading
                              ? _buildSkeletonLoading()
                              : _buildContentArea(),
                        ),
                      ],
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

  Widget _buildContentArea() {
    switch (_activeNav) {
      case VortexNavTarget.settings:
        return VortexSettingsView(
          onBackToSidebar: _focusSidebar,
          onDataChanged: () async {
            _cachedAllChannels = null;
            final favCats = await PreferencesService.getFavoriteCategories();
            _favoriteCategories = favCats.toSet();
          },
        );
      case VortexNavTarget.home:
        return VortexHomeView(
          shelves: _shelves,
          mainScrollController: _mainScrollController,
          shelfScrollControllers: _shelfScrollControllers,
          currentZone: _currentZone,
          focusedShelfIndex: _focusedShelfIndex,
          focusedItemIndex: _focusedItemIndex,
          onItemTap: (item, shelfIdx, itemIdx) {
            setState(() {
              _currentZone = VortexZone.content;
              _focusedShelfIndex = shelfIdx;
              _focusedItemIndex = itemIdx;
            });
            _playItem(item);
          },
          onAddCategoriesTap: () {
            setState(() {
              _activeNav = VortexNavTarget.settings;
              _focusedNavIndex = 5;
            });
          },
        );
      case VortexNavTarget.liveTv:
        return VortexLiveView(
          items: _filteredScopedItems,
          favoriteCategories: _favoriteCategories,
          activeFilter: _activeFilter,
          currentZone: _currentZone,
          focusedGridIndex: _focusedGridIndex,
          mainScrollController: _mainScrollController,
          cardKeys: _cardKeys,
          onItemTap: (item, globalIdx) {
            setState(() {
              _currentZone = VortexZone.content;
              _focusedGridIndex = globalIdx;
              _lastFocusedGridIndex = globalIdx;
            });
            _playItem(item);
          },
        );
      case VortexNavTarget.movies:
        return VortexMoviesView(
          items: _filteredScopedItems,
          favoriteCategories: _favoriteCategories,
          activeFilter: _activeFilter,
          currentZone: _currentZone,
          focusedGridIndex: _focusedGridIndex,
          mainScrollController: _mainScrollController,
          cardKeys: _cardKeys,
          onItemTap: (item, globalIdx) {
            setState(() {
              _currentZone = VortexZone.content;
              _focusedGridIndex = globalIdx;
              _lastFocusedGridIndex = globalIdx;
            });
            _playItem(item);
          },
        );
      case VortexNavTarget.series:
        return VortexSeriesView(
          items: _filteredScopedItems,
          favoriteCategories: _favoriteCategories,
          activeFilter: _activeFilter,
          currentZone: _currentZone,
          focusedGridIndex: _focusedGridIndex,
          mainScrollController: _mainScrollController,
          cardKeys: _cardKeys,
          onItemTap: (item, globalIdx) {
            setState(() {
              _currentZone = VortexZone.content;
              _focusedGridIndex = globalIdx;
              _lastFocusedGridIndex = globalIdx;
            });
            _playItem(item);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      itemCount: 3,
      itemBuilder: (context, idx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 180,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1F),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  itemBuilder: (context, cIdx) {
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161618),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222226)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopFilterBar() {
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
      if (!isLiveTv) ...[
        _buildFilterPill('Recently Watched', _activeFilter == VortexActiveFilter.recent, 1, () {
          setState(() {
            _activeFilter = VortexActiveFilter.recent;
            _applyFilter();
          });
        }),
        _buildFilterPill('In Progress', _activeFilter == VortexActiveFilter.inProgress, 2, () {
          setState(() {
            _activeFilter = VortexActiveFilter.inProgress;
            _applyFilter();
          });
        }),
      ],
    ];

    final offset = isLiveTv ? 1 : 3;
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
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
}
