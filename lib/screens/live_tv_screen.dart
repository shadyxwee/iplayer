import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

enum NavigationZone { categories, channels, playerSurface, playerControls }

enum PlayerControlTarget { playPause, volume, aspectRatio, favorite, fullscreen }

enum SearchTarget { channels, categories }

class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  // Navigation & Spatial Focus State
  NavigationZone _currentZone = NavigationZone.channels;
  int _focusedCategoryIndex = 0;
  int _focusedChannelIndex = 0;
  PlayerControlTarget _focusedControl = PlayerControlTarget.playPause;

  // Focus & Scroll Controllers
  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _channelScrollController = ScrollController();

  // Data State
  List<String> _allCategories = ['All'];
  List<String> _filteredCategories = ['All'];
  Set<String> _favoriteCategories = {};
  String _selectedCategory = 'All';
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  Channel? _selectedChannel;
  String _searchQuery = '';
  SearchTarget _searchTarget = SearchTarget.channels;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Player State
  Player? _player;
  VideoController? _controller;
  bool _isPlayerLoading = false;
  String? _playerError;
  bool _isFullscreen = false;
  bool _isPlaying = false;
  double _volume = 100.0;
  String _aspectRatioMode = '16:9';
  StreamSubscription<bool>? _playingSubscription;

  // Controls Visibility & Auto-Hide Timer
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isControlsVisible && !_screenFocusNode.hasFocus) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    if (!_isControlsVisible) {
      setState(() {
        _isControlsVisible = true;
      });
    }
    _startHideControlsTimer();
  }

  Future<void> _loadData() async {
    final channels = await DatabaseService.getAllChannels();
    final liveChannels = channels.where((c) => c.contentType == ContentType.live).toList();

    final categorySet = <String>{'All'};
    for (final c in liveChannels) {
      if (c.group != null && c.group!.isNotEmpty) {
        categorySet.add(c.group!);
      }
    }

    final categories = categorySet.toList();

    List<Channel> displayChannels = liveChannels;
    if (displayChannels.isEmpty) {
      displayChannels = _generateSampleChannels();
    }

    // Load favorite categories
    final favCategoriesList = await PreferencesService.getFavoriteCategories();
    final favCategoriesSet = favCategoriesList.toSet();

    // State persistence: restore last selected category
    final savedCategory = await PreferencesService.getLastSelectedCategory();
    String activeCategory = 'All';
    if (savedCategory != null && categories.contains(savedCategory)) {
      activeCategory = savedCategory;
    }

    final catIndex = categories.indexOf(activeCategory);

    // Filter channels for the selected category
    List<Channel> initialFilteredChannels = displayChannels;
    if (activeCategory != 'All') {
      initialFilteredChannels = displayChannels.where((c) => c.group == activeCategory).toList();
    }

    // Restore last focused channel inside this category
    final savedChannelName = await PreferencesService.getLastFocusedChannel(activeCategory);
    int initialChannelIndex = 0;
    if (savedChannelName != null) {
      final foundIdx = initialFilteredChannels.indexWhere((c) => c.name == savedChannelName);
      if (foundIdx != -1) {
        initialChannelIndex = foundIdx;
      }
    }

    setState(() {
      _allChannels = displayChannels;
      _filteredChannels = initialFilteredChannels;
      _allCategories = categories;
      _filteredCategories = categories;
      _favoriteCategories = favCategoriesSet;
      _selectedCategory = activeCategory;
      _focusedCategoryIndex = catIndex != -1 ? catIndex : 0;
      _focusedChannelIndex = initialChannelIndex;
      _isLoading = false;

      if (_filteredChannels.isNotEmpty) {
        _selectedChannel = _filteredChannels[_focusedChannelIndex];
        _initPlayerForChannel(_selectedChannel!);
      }
    });
  }

  List<Channel> _generateSampleChannels() {
    final names = [
      'MEGA', 'MEGA HD', 'MEGA FHD', 'MEGA 2', 'MEGA Plus', 'Meganoticias',
      'CHV', 'CHV HD', 'CHV FHD', 'CHV FHD 2', 'CHV Noticias', 'CHV Deportes',
      'Canal 13', 'Canal 13 HD', 'Canal 13 FHD', 'Canal 13 FHD 2', '13c', 'T13',
      '13 Cultura', '13 Deportes', '13 Internacional', '13 Festival', '13 Cocina', '13 Viajes', '13 Pop'
    ];

    return List.generate(names.length, (index) {
      final ch = Channel();
      ch.number = index + 1;
      ch.name = names[index];
      ch.group = 'Chile';
      ch.url = 'https://demo.unified-streaming.com/k8s/features/stable/hls-demo/m3u8-out/clear/master.m3u8';
      ch.contentType = ContentType.live;
      return ch;
    });
  }

  Future<void> _initPlayerForChannel(Channel channel) async {
    setState(() {
      _isPlayerLoading = true;
      _playerError = null;
    });

    try {
      final newPlayer = Player();
      final newController = VideoController(newPlayer);

      try {
        final dynamic native = newPlayer.platform;
        native.setProperty('cache-pause', 'yes');
        native.setProperty('demuxer-readahead-secs', '15');
      } catch (_) {}

      // Keep play/pause button state in perfect sync
      _playingSubscription?.cancel();
      _playingSubscription = newPlayer.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });

      final Map<String, String> headers = {
        'User-Agent': channel.userAgent ?? 'Mozilla/5.0 (Linux; Android 10) IPTV-Player/1.0',
        'Connection': 'keep-alive',
      };
      if (channel.referer != null) {
        headers['Referer'] = channel.referer!;
      }

      await newPlayer.open(
        Media(
          channel.url,
          httpHeaders: headers,
        ),
        play: true,
      );

      if (mounted) {
        setState(() {
          _player?.dispose();
          _player = newPlayer;
          _controller = newController;
          _isPlayerLoading = false;
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playerError = e.toString();
          _isPlayerLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  void _filterData() {
    if (_searchTarget == SearchTarget.categories) {
      // Filter categories
      if (_searchQuery.trim().isEmpty) {
        _filteredCategories = _allCategories;
      } else {
        _filteredCategories = _allCategories
            .where((cat) => cat.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
      _focusedCategoryIndex = 0;
      // Filter channels for the selected category
      _filterChannelsOnly();
    } else {
      // Filter channels
      _filteredCategories = _allCategories;
      _filterChannelsOnly();
    }
  }

  void _filterChannelsOnly() {
    List<Channel> filtered = _allChannels;

    if (_selectedCategory != 'All') {
      filtered = filtered.where((c) => c.group == _selectedCategory).toList();
    }

    if (_searchTarget == SearchTarget.channels && _searchQuery.trim().isNotEmpty) {
      filtered = filtered
          .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredChannels = filtered;
      _focusedChannelIndex = 0;
    });
  }

  // --- D-Pad Spatial Navigation Dispatcher ---
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Fullscreen exit via Escape key must always work immediately
    if (key == LogicalKeyboardKey.escape) {
      if (_isFullscreen) {
        _toggleFullscreen();
        return;
      }
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
        return;
      }
      _handleBack();
      return;
    }

    // Guard: ignore arrow navigation if typing in search input field
    if (_searchFocusNode.hasFocus) {
      if (key == LogicalKeyboardKey.arrowDown) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
        setState(() {
          _currentZone = NavigationZone.channels;
        });
      }
      return;
    }

    _showControls();

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
    } else if (key == LogicalKeyboardKey.goBack) {
      _handleBack();
    }
  }

  void _moveUp() {
    setState(() {
      switch (_currentZone) {
        case NavigationZone.categories:
          if (_focusedCategoryIndex > 0) {
            _focusedCategoryIndex--;
            _ensureVisibleCategory(_focusedCategoryIndex);
          }
          break;

        case NavigationZone.channels:
          if (_focusedChannelIndex > 0) {
            _focusedChannelIndex--;
            _ensureVisibleChannel(_focusedChannelIndex);
          }
          break;

        case NavigationZone.playerControls:
          _currentZone = NavigationZone.playerSurface;
          break;

        case NavigationZone.playerSurface:
          _currentZone = NavigationZone.channels;
          break;
      }
    });
  }

  void _moveDown() {
    setState(() {
      switch (_currentZone) {
        case NavigationZone.categories:
          if (_focusedCategoryIndex < _filteredCategories.length - 1) {
            _focusedCategoryIndex++;
            _ensureVisibleCategory(_focusedCategoryIndex);
          }
          break;

        case NavigationZone.channels:
          if (_focusedChannelIndex < _filteredChannels.length - 1) {
            _focusedChannelIndex++;
            _ensureVisibleChannel(_focusedChannelIndex);
          }
          break;

        case NavigationZone.playerSurface:
          _currentZone = NavigationZone.playerControls;
          _focusedControl = PlayerControlTarget.playPause;
          break;

        case NavigationZone.playerControls:
          break;
      }
    });
  }

  void _moveLeft() {
    setState(() {
      switch (_currentZone) {
        case NavigationZone.categories:
          break;

        case NavigationZone.channels:
          _currentZone = NavigationZone.categories;
          // Sync focused category index to selected category
          final idx = _filteredCategories.indexOf(_selectedCategory);
          if (idx != -1) {
            _focusedCategoryIndex = idx;
            _ensureVisibleCategory(_focusedCategoryIndex);
          }
          break;

        case NavigationZone.playerSurface:
        case NavigationZone.playerControls:
          if (_currentZone == NavigationZone.playerControls &&
              _focusedControl != PlayerControlTarget.playPause) {
            final prevIndex = PlayerControlTarget.values.indexOf(_focusedControl) - 1;
            if (prevIndex >= 0) {
              _focusedControl = PlayerControlTarget.values[prevIndex];
            } else {
              _currentZone = NavigationZone.channels;
              _ensureVisibleChannel(_focusedChannelIndex);
            }
          } else {
            _currentZone = NavigationZone.channels;
            _ensureVisibleChannel(_focusedChannelIndex);
          }
          break;
      }
    });
  }

  void _moveRight() {
    setState(() {
      switch (_currentZone) {
        case NavigationZone.categories:
          _currentZone = NavigationZone.channels;
          _ensureVisibleChannel(_focusedChannelIndex);
          break;

        case NavigationZone.channels:
          _currentZone = NavigationZone.playerControls;
          _focusedControl = PlayerControlTarget.playPause;
          break;

        case NavigationZone.playerControls:
          final nextIndex = PlayerControlTarget.values.indexOf(_focusedControl) + 1;
          if (nextIndex < PlayerControlTarget.values.length) {
            _focusedControl = PlayerControlTarget.values[nextIndex];
          }
          break;

        case NavigationZone.playerSurface:
          break;
      }
    });
  }

  void _activateCurrent() {
    switch (_currentZone) {
      case NavigationZone.categories:
        if (_focusedCategoryIndex < _filteredCategories.length) {
          final cat = _filteredCategories[_focusedCategoryIndex];
          setState(() {
            _selectedCategory = cat;
            PreferencesService.setLastSelectedCategory(cat);
            _filterChannelsOnly();
          });
        }
        break;

      case NavigationZone.channels:
        if (_focusedChannelIndex < _filteredChannels.length) {
          final selected = _filteredChannels[_focusedChannelIndex];
          setState(() {
            _selectedChannel = selected;
          });
          PreferencesService.setLastFocusedChannel(_selectedCategory, selected.name);
          _initPlayerForChannel(selected);
        }
        break;

      case NavigationZone.playerSurface:
        _togglePlayPause();
        break;

      case NavigationZone.playerControls:
        _executeControlAction(_focusedControl);
        break;
    }
  }

  void _togglePlayPause() {
    if (_player != null) {
      _player!.playOrPause();
    }
  }

  void _executeControlAction(PlayerControlTarget target) {
    switch (target) {
      case PlayerControlTarget.playPause:
        _togglePlayPause();
        break;

      case PlayerControlTarget.volume:
        setState(() {
          _volume = _volume > 0 ? 0.0 : 100.0;
          _player?.setVolume(_volume);
        });
        break;

      case PlayerControlTarget.aspectRatio:
        setState(() {
          _aspectRatioMode = _aspectRatioMode == '16:9' ? '4:3' : '16:9';
        });
        break;

      case PlayerControlTarget.favorite:
        if (_selectedChannel != null) {
          DatabaseService.toggleFavorite(_selectedChannel!);
          setState(() {});
        }
        break;

      case PlayerControlTarget.fullscreen:
        _toggleFullscreen();
        break;
    }
  }

  void _handleBack() {
    if (_isFullscreen) {
      _toggleFullscreen();
    } else if (_currentZone != NavigationZone.channels) {
      setState(() {
        _currentZone = NavigationZone.channels;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.setFullScreen(_isFullscreen);
    } else if (!kIsWeb && Platform.isAndroid) {
      if (_isFullscreen) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  /// Scrolling with center alignment so focused item does not get pinned to top
  void _ensureVisibleCategory(int index) {
    if (!_categoryScrollController.hasClients) return;
    const double itemHeight = 36.0;
    final double viewportHeight = _categoryScrollController.position.viewportDimension;
    final double targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    final double clampedOffset = targetOffset.clamp(
      0.0,
      _categoryScrollController.position.maxScrollExtent,
    );

    _categoryScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  /// Scrolling with center alignment so focused channel is kept in comfortable view
  void _ensureVisibleChannel(int index) {
    if (!_channelScrollController.hasClients) return;
    const double itemHeight = 56.0;
    final double viewportHeight = _channelScrollController.position.viewportDimension;
    final double targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    final double clampedOffset = targetOffset.clamp(
      0.0,
      _channelScrollController.position.maxScrollExtent,
    );

    _channelScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _playingSubscription?.cancel();
    _screenFocusNode.dispose();
    _searchFocusNode.dispose();
    _categoryScrollController.dispose();
    _channelScrollController.dispose();
    _searchController.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0C13),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5764D8))),
      );
    }

    return KeyboardListener(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0C13),
        body: MouseRegion(
          onHover: (_) => _showControls(),
          onEnter: (_) => _showControls(),
          child: SafeArea(
            child: Row(
              children: [
                if (!_isFullscreen) ...[
                  _buildCategorySidebar(),
                  _buildChannelColumn(),
                ],
                Expanded(child: _buildMainPlayerViewport()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Zone A: Category Sidebar (200px) ---
  Widget _buildCategorySidebar() {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D16),
        border: Border(right: BorderSide(color: Color(0xFF191C2B), width: 1)),
      ),
      child: Column(
        children: [
          // Top Header / LIVE TV Pill
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF181A28), width: 1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF7D869E), size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5283B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'LIVE TV',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category Scroll List
          Expanded(
            child: _filteredCategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No categories matching "$_searchQuery"',
                        style: const TextStyle(color: Color(0xFF737C98), fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _categoryScrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      final isSelected = category == _selectedCategory;
                      final isFocused = _currentZone == NavigationZone.categories && index == _focusedCategoryIndex;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _currentZone = NavigationZone.categories;
                            _focusedCategoryIndex = index;
                            _selectedCategory = category;
                            PreferencesService.setLastSelectedCategory(category);
                            _filterChannelsOnly();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? const Color(0xFF252A42)
                                : isSelected
                                    ? const Color(0xFF1A1D30).withValues(alpha: 0.6)
                                    : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isFocused
                                    ? const Color(0xFF00E5FF)
                                    : isSelected
                                        ? const Color(0xFF5764D8)
                                        : Colors.transparent,
                                width: isFocused ? 3 : 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isFocused || isSelected ? Colors.white : const Color(0xFF737C98),
                                    fontSize: 11,
                                    fontWeight: isSelected || isFocused ? FontWeight.bold : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (category != 'All')
                                GestureDetector(
                                  onTap: () async {
                                    final isNowFav = await PreferencesService.toggleFavoriteCategory(category);
                                    setState(() {
                                      if (isNowFav) {
                                        _favoriteCategories.add(category);
                                      } else {
                                        _favoriteCategories.remove(category);
                                      }
                                    });
                                  },
                                  child: Icon(
                                    _favoriteCategories.contains(category)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 14,
                                    color: _favoriteCategories.contains(category)
                                        ? const Color(0xFFE5283B)
                                        : const Color(0xFF555D77),
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

  // --- Zone B: Channel Column (310px) ---
  Widget _buildChannelColumn() {
    return Container(
      width: 310,
      decoration: const BoxDecoration(
        color: Color(0xFF111320),
        border: Border(right: BorderSide(color: Color(0xFF1A1C2D), width: 1)),
      ),
      child: Column(
        children: [
          // Search Bar & Filter Target Toggle
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1B1E30), width: 1)),
            ),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171A2B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF24283F),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF5E6682), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: _searchTarget == SearchTarget.channels
                                ? 'Search Channels...'
                                : 'Search Categories...',
                            hintStyle: const TextStyle(color: Color(0xFF575F7A), fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                            _filterData();
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _filterData();
                          },
                          child: const Icon(Icons.clear, color: Color(0xFF707994), size: 16),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Radio Target Selector: Categories vs Channels
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSearchTargetOption(SearchTarget.channels, 'Channels'),
                    const SizedBox(width: 12),
                    _buildSearchTargetOption(SearchTarget.categories, 'Categories'),
                  ],
                ),
              ],
            ),
          ),

          // Channel Rows List or Empty State
          Expanded(
            child: _filteredChannels.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, color: Color(0xFF555D77), size: 40),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No items matching "$_searchQuery"'
                                : 'No channels available in "$_selectedCategory"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF8F98B6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _channelScrollController,
                    itemCount: _filteredChannels.length,
                    itemBuilder: (context, index) {
                      final channel = _filteredChannels[index];
                      final isSelected = _selectedChannel?.name == channel.name;
                      final isFocused = _currentZone == NavigationZone.channels && index == _focusedChannelIndex;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _currentZone = NavigationZone.channels;
                            _focusedChannelIndex = index;
                            _selectedChannel = channel;
                            PreferencesService.setLastFocusedChannel(_selectedCategory, channel.name);
                            _initPlayerForChannel(channel);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? const Color(0xFF232747)
                                : isSelected
                                    ? const Color(0xFF1F233F)
                                    : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isFocused
                                    ? const Color(0xFF00E5FF)
                                    : isSelected
                                        ? const Color(0xFF5B68DF)
                                        : Colors.transparent,
                                width: isFocused ? 3 : 2,
                              ),
                              bottom: const BorderSide(color: Color(0xFF171A2A), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${channel.number ?? index + 1}',
                                  style: TextStyle(
                                    color: isSelected || isFocused ? Colors.white : const Color(0xFF555D77),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE85817),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${channel.number ?? index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      channel.name,
                                      style: TextStyle(
                                        color: isSelected || isFocused ? Colors.white : const Color(0xFFCFD3E3),
                                        fontSize: 12,
                                        fontWeight: isSelected || isFocused ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      channel.group ?? 'General',
                                      style: const TextStyle(color: Color(0xFF555D77), fontSize: 10, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildSearchTargetOption(SearchTarget target, String label) {
    final isSelected = _searchTarget == target;
    return InkWell(
      onTap: () {
        setState(() {
          _searchTarget = target;
          _filterData();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF555D77),
                  width: 1.5,
                ),
                color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF737C98),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Zone C: Main Player Viewport & OSD ---
  Widget _buildMainPlayerViewport() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Player Canvas
          Positioned.fill(
            child: _isPlayerLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5283B)))
                : _playerError != null
                    ? Center(
                        child: Text(
                          _playerError!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      )
                    : _controller != null
                        ? Video(controller: _controller!, controls: NoVideoControls)
                        : const SizedBox.shrink(),
          ),

          // Header Overlay (Only when not fullscreen)
          if (!_isFullscreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: const Color(0xFF0E101A).withValues(alpha: 0.7),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedChannel?.name ?? 'Canal 13',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          (_selectedChannel?.group ?? 'General').toUpperCase(),
                          style: const TextStyle(color: Color(0xFF69728F), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Control Ribbon Overlay (Auto-hiding)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Bar
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 4,
                          width: 200,
                          color: const Color(0xFFE5283B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Controls Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildControlButton(
                              target: PlayerControlTarget.playPause,
                              icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                              onTap: _togglePlayPause,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5283B).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5283B).withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(radius: 3, backgroundColor: Color(0xFFE5283B)),
                                  SizedBox(width: 4),
                                  Text(
                                    'EN VIVO',
                                    style: TextStyle(color: Color(0xFFE5283B), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildControlButton(
                              target: PlayerControlTarget.volume,
                              icon: _volume > 0 ? Icons.volume_up : Icons.volume_off,
                              onTap: () {
                                setState(() {
                                  _volume = _volume > 0 ? 0.0 : 100.0;
                                  _player?.setVolume(_volume);
                                });
                              },
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            _buildControlButton(
                              target: PlayerControlTarget.aspectRatio,
                              icon: Icons.aspect_ratio,
                              label: _aspectRatioMode,
                              onTap: () {
                                setState(() {
                                  _aspectRatioMode = _aspectRatioMode == '16:9' ? '4:3' : '16:9';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildControlButton(
                              target: PlayerControlTarget.favorite,
                              icon: _selectedChannel?.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                              color: _selectedChannel?.isFavorite == true ? const Color(0xFFE41E57) : Colors.white70,
                              onTap: () {
                                if (_selectedChannel != null) {
                                  DatabaseService.toggleFavorite(_selectedChannel!);
                                  setState(() {});
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildControlButton(
                              target: PlayerControlTarget.fullscreen,
                              icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              onTap: _toggleFullscreen,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildControlButton({
    required PlayerControlTarget target,
    required IconData icon,
    String? label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isFocused = _currentZone == NavigationZone.playerControls && _focusedControl == target;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isFocused ? const Color(0xFF252A42) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isFocused ? const Color(0xFF00E5FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? (isFocused ? Colors.white : const Color(0xFF8F98B6)), size: 18),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: isFocused ? Colors.white : const Color(0xFF8F98B6), fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
