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

enum NavigationZone { categories, channels, playerSurface, playerControls }

enum PlayerControlTarget {
  playPrevious,
  playPause,
  playNext,
  fullscreen,
  volumeDown,
  volumeMute,
  volumeUp,
  subtitles,
  favorite,
}

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
  final FocusNode _keyboardListenerFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _channelScrollController = ScrollController();

  // Data State
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  Channel? _selectedChannel;
  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Player State
  Player? _player;
  VideoController? _controller;
  bool _isPlayerLoading = false;
  String? _playerError;
  bool _isFullscreen = false;
  double _volume = 100.0;
  bool _subtitlesEnabled = true;

  // Autoplay Debounce Timer
  Timer? _autoplayDebounceTimer;

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
      if (mounted && _isControlsVisible) {
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

    // Deduplicate channels by name
    final seenNames = <String>{};
    final uniqueLiveChannels = <Channel>[];
    for (final c in liveChannels) {
      if (!seenNames.contains(c.name.toLowerCase())) {
        seenNames.add(c.name.toLowerCase());
        uniqueLiveChannels.add(c);
      }
    }

    final categorySet = <String>{'All'};
    for (final c in uniqueLiveChannels) {
      if (c.group != null && c.group!.isNotEmpty) {
        categorySet.add(c.group!);
      }
    }

    final categories = categorySet.toList();

    List<Channel> displayChannels = uniqueLiveChannels;
    if (displayChannels.isEmpty) {
      displayChannels = _generateSampleChannels();
    }

    setState(() {
      _allChannels = displayChannels;
      _filteredChannels = displayChannels;
      _categories = categories;
      _isLoading = false;

      if (_filteredChannels.isNotEmpty) {
        _selectedChannel = _filteredChannels.first;
        _focusedChannelIndex = 0;
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

  void _onChannelFocusChanged(int newIndex) {
    _focusedChannelIndex = newIndex;
    _ensureVisibleChannelCentered(_focusedChannelIndex);

    _autoplayDebounceTimer?.cancel();
    _autoplayDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _focusedChannelIndex < _filteredChannels.length) {
        final targetChannel = _filteredChannels[_focusedChannelIndex];
        if (_selectedChannel?.name != targetChannel.name) {
          setState(() {
            _selectedChannel = targetChannel;
          });
          _initPlayerForChannel(targetChannel);
        }
      }
    });
  }

  Future<void> _initPlayerForChannel(Channel channel) async {
    _player?.dispose();
    _player = null;
    _controller = null;

    setState(() {
      _isPlayerLoading = true;
      _playerError = null;
    });

    final newPlayer = Player();
    final newController = VideoController(newPlayer);

    try {
      try {
        final dynamic native = newPlayer.platform;
        native.setProperty('cache-pause', 'yes');
        native.setProperty('demuxer-readahead-secs', '15');
      } catch (_) {}

      await newPlayer.open(
        Media(
          channel.url,
          httpHeaders: {
            'User-Agent': channel.userAgent ?? 'Mozilla/5.0 (Linux; Android 10) IPTV-Player/1.0',
            if (channel.referer != null) 'Referer': channel.referer!,
          },
        ),
        play: true,
      );

      if (mounted) {
        setState(() {
          _player = newPlayer;
          _controller = newController;
          _isPlayerLoading = false;
        });
      } else {
        newPlayer.dispose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playerError = e.toString();
          _isPlayerLoading = false;
        });
      } else {
        newPlayer.dispose();
      }
    }
  }

  void _filterChannels() {
    List<Channel> filtered = _allChannels;

    if (_selectedCategory != 'All') {
      filtered = filtered.where((c) => c.group == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Deduplicate
    final seen = <String>{};
    final uniqueList = <Channel>[];
    for (final c in filtered) {
      if (!seen.contains(c.name.toLowerCase())) {
        seen.add(c.name.toLowerCase());
        uniqueList.add(c);
      }
    }

    setState(() {
      _filteredChannels = uniqueList;
      _focusedChannelIndex = 0;
    });
  }

  void _playPreviousChannel() {
    if (_filteredChannels.isEmpty) return;
    final currentIndex = _filteredChannels.indexWhere((c) => c.name == _selectedChannel?.name);
    final prevIndex = (currentIndex - 1 + _filteredChannels.length) % _filteredChannels.length;
    setState(() {
      _focusedChannelIndex = prevIndex;
      _selectedChannel = _filteredChannels[prevIndex];
      _ensureVisibleChannelCentered(prevIndex);
    });
    _initPlayerForChannel(_selectedChannel!);
  }

  void _playNextChannel() {
    if (_filteredChannels.isEmpty) return;
    final currentIndex = _filteredChannels.indexWhere((c) => c.name == _selectedChannel?.name);
    final nextIndex = (currentIndex + 1) % _filteredChannels.length;
    setState(() {
      _focusedChannelIndex = nextIndex;
      _selectedChannel = _filteredChannels[nextIndex];
      _ensureVisibleChannelCentered(nextIndex);
    });
    _initPlayerForChannel(_selectedChannel!);
  }

  // --- D-Pad Spatial Navigation Dispatcher ---
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_searchFocusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _searchFocusNode.unfocus();
        _screenFocusNode.requestFocus();
      }
      return;
    }

    _showControls();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      _moveUp();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _moveDown();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _moveLeft();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _moveRight();
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.space) {
      _activateCurrent();
    } else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
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
            _onChannelFocusChanged(_focusedChannelIndex - 1);
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
          if (_focusedCategoryIndex < _categories.length - 1) {
            _focusedCategoryIndex++;
            _ensureVisibleCategory(_focusedCategoryIndex);
          }
          break;

        case NavigationZone.channels:
          if (_focusedChannelIndex < _filteredChannels.length - 1) {
            _onChannelFocusChanged(_focusedChannelIndex + 1);
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
          break;

        case NavigationZone.playerSurface:
        case NavigationZone.playerControls:
          if (_currentZone == NavigationZone.playerControls && _focusedControl != PlayerControlTarget.playPrevious) {
            final prevIndex = PlayerControlTarget.values.indexOf(_focusedControl) - 1;
            if (prevIndex >= 0) {
              _focusedControl = PlayerControlTarget.values[prevIndex];
            } else {
              _currentZone = NavigationZone.channels;
            }
          } else {
            _currentZone = NavigationZone.channels;
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
        setState(() {
          _selectedCategory = _categories[_focusedCategoryIndex];
          _filterChannels();
        });
        break;

      case NavigationZone.channels:
        if (_focusedChannelIndex < _filteredChannels.length) {
          final selected = _filteredChannels[_focusedChannelIndex];
          setState(() {
            _selectedChannel = selected;
          });
          _initPlayerForChannel(selected);
        }
        break;

      case NavigationZone.playerSurface:
        _player?.playOrPause();
        break;

      case NavigationZone.playerControls:
        _executeControlAction(_focusedControl);
        break;
    }
  }

  void _executeControlAction(PlayerControlTarget target) {
    switch (target) {
      case PlayerControlTarget.playPrevious:
        _playPreviousChannel();
        break;

      case PlayerControlTarget.playPause:
        _player?.playOrPause();
        break;

      case PlayerControlTarget.playNext:
        _playNextChannel();
        break;

      case PlayerControlTarget.fullscreen:
        _toggleFullscreen();
        break;

      case PlayerControlTarget.volumeDown:
        setState(() {
          _volume = (_volume - 10.0).clamp(0.0, 100.0);
          _player?.setVolume(_volume);
        });
        break;

      case PlayerControlTarget.volumeMute:
        setState(() {
          _volume = _volume > 0 ? 0.0 : 100.0;
          _player?.setVolume(_volume);
        });
        break;

      case PlayerControlTarget.volumeUp:
        setState(() {
          _volume = (_volume + 10.0).clamp(0.0, 100.0);
          _player?.setVolume(_volume);
        });
        break;

      case PlayerControlTarget.subtitles:
        setState(() {
          _subtitlesEnabled = !_subtitlesEnabled;
          if (_subtitlesEnabled) {
            _player?.setSubtitleTrack(SubtitleTrack.auto());
          } else {
            _player?.setSubtitleTrack(SubtitleTrack.no());
          }
        });
        break;

      case PlayerControlTarget.favorite:
        if (_selectedChannel != null) {
          DatabaseService.toggleFavorite(_selectedChannel!);
          setState(() {});
        }
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

  void _ensureVisibleCategory(int index) {
    if (_categoryScrollController.hasClients) {
      _categoryScrollController.animateTo(
        (index * 32.0).clamp(0.0, _categoryScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  /// Centers the focused/selected channel in the viewport until top/bottom bounds
  void _ensureVisibleChannelCentered(int index) {
    if (_channelScrollController.hasClients) {
      const itemHeight = 48.0;
      final viewportHeight = _channelScrollController.position.viewportDimension;
      final targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);

      _channelScrollController.animateTo(
        targetOffset.clamp(0.0, _channelScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _autoplayDebounceTimer?.cancel();
    _hideControlsTimer?.cancel();
    _screenFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    _searchFocusNode.dispose();
    _categoryScrollController.dispose();
    _channelScrollController.dispose();
    _searchController.dispose();
    _player?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0C13),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5764D8))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 768;

        return Focus(
          focusNode: _screenFocusNode,
          autofocus: true,
          child: KeyboardListener(
            focusNode: _keyboardListenerFocusNode,
            onKeyEvent: _handleKeyEvent,
            child: Scaffold(
              backgroundColor: const Color(0xFF0B0C13),
              body: MouseRegion(
                onHover: (_) => _showControls(),
                onEnter: (_) => _showControls(),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (!_isFullscreen && !isNarrow) ...[
                        _buildCategorySidebar(),
                        _buildChannelColumn(),
                      ],
                      Expanded(child: _buildMainPlayerViewport()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

          Expanded(
            child: ListView.builder(
              controller: _categoryScrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                final isFocused = _currentZone == NavigationZone.categories && index == _focusedCategoryIndex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentZone = NavigationZone.categories;
                      _focusedCategoryIndex = index;
                      _selectedCategory = category;
                      _filterChannels();
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
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1B1E30), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171A2B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF24283F)),
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
                            decoration: const InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Color(0xFF575F7A), fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                              _filterChannels();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF707994), size: 16),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _channelScrollController,
              itemCount: _filteredChannels.length,
              itemBuilder: (context, index) {
                final channel = _filteredChannels[index];
                final isSelected = _selectedChannel?.name == channel.name;
                final isFocused = _currentZone == NavigationZone.channels && index == _focusedChannelIndex;
                final logoUrl = channel.logo ?? channel.tvgLogo;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentZone = NavigationZone.channels;
                      _focusedChannelIndex = index;
                      _selectedChannel = channel;
                      _initPlayerForChannel(channel);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF2B3054), Color(0xFF1F233F)],
                            )
                          : isFocused
                              ? const LinearGradient(
                                  colors: [Color(0xFF232747), Color(0xFF1A1D36)],
                                )
                              : null,
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
                          width: 20,
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
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1F30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2A2E45)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: logoUrl != null && logoUrl.isNotEmpty
                              ? Image.network(
                                  logoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _buildChannelBadgeFallback(channel, index),
                                )
                              : _buildChannelBadgeFallback(channel, index),
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
                                channel.group ?? 'Chile',
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

  Widget _buildChannelBadgeFallback(Channel channel, int index) {
    return Container(
      color: const Color(0xFFE85817),
      alignment: Alignment.center,
      child: Text(
        '${channel.number ?? index + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  // --- Zone C: Main Player Viewport & Exact OSD Ribbon Flow ---
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

          // Header Overlay
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
                          (_selectedChannel?.group ?? 'Chile').toUpperCase(),
                          style: const TextStyle(color: Color(0xFF69728F), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Control Ribbon Overlay
          // Exact Flow: Play Previous | Play/Pause | Play Next | Full Screen Button | Sound Manage | Subtitle On/Off | Love Icon
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
                    // Dynamic Stream Progress Bar
                    if (_player != null)
                      StreamBuilder<Duration>(
                        stream: _player!.stream.position,
                        builder: (context, posSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: _player!.stream.duration,
                            builder: (context, durSnapshot) {
                              final pos = posSnapshot.data ?? Duration.zero;
                              final dur = durSnapshot.data ?? Duration.zero;
                              final progress = dur.inMilliseconds > 0
                                  ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                                  : 1.0;

                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(pos), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                      Text(_formatDuration(dur), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: progress,
                                        child: Container(
                                          height: 4,
                                          color: const Color(0xFFE5283B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 10),

                    // Controls Row with Exact Sequence Requirements
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Cluster: Play Previous | Play/Pause | Play Next | Full Screen
                        Row(
                          children: [
                            // 1. Play Previous Channel
                            _buildControlButton(
                              target: PlayerControlTarget.playPrevious,
                              icon: Icons.skip_previous,
                              onTap: _playPreviousChannel,
                            ),
                            const SizedBox(width: 8),

                            // 2. Play / Pause
                            _buildControlButton(
                              target: PlayerControlTarget.playPause,
                              icon: Icons.pause,
                              onTap: () => _player?.playOrPause(),
                            ),
                            const SizedBox(width: 8),

                            // 3. Play Next Channel
                            _buildControlButton(
                              target: PlayerControlTarget.playNext,
                              icon: Icons.skip_next,
                              onTap: _playNextChannel,
                            ),
                            const SizedBox(width: 12),

                            // 4. Full Screen Button
                            _buildControlButton(
                              target: PlayerControlTarget.fullscreen,
                              icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              onTap: _toggleFullscreen,
                            ),
                          ],
                        ),

                        // Right Cluster: Sound Manage | Subtitle On/Off | Love Icon
                        Row(
                          children: [
                            // 5. Sound Manage (- , Mute , +)
                            _buildControlButton(
                              target: PlayerControlTarget.volumeDown,
                              icon: Icons.remove,
                              onTap: () {
                                setState(() {
                                  _volume = (_volume - 10.0).clamp(0.0, 100.0);
                                  _player?.setVolume(_volume);
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildControlButton(
                              target: PlayerControlTarget.volumeMute,
                              icon: _volume > 0 ? Icons.volume_up : Icons.volume_off,
                              onTap: () {
                                setState(() {
                                  _volume = _volume > 0 ? 0.0 : 100.0;
                                  _player?.setVolume(_volume);
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildControlButton(
                              target: PlayerControlTarget.volumeUp,
                              icon: Icons.add,
                              onTap: () {
                                setState(() {
                                  _volume = (_volume + 10.0).clamp(0.0, 100.0);
                                  _player?.setVolume(_volume);
                                });
                              },
                            ),
                            const SizedBox(width: 12),

                            // 6. Subtitle On/Off
                            _buildControlButton(
                              target: PlayerControlTarget.subtitles,
                              icon: _subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
                              label: _subtitlesEnabled ? 'SUB ON' : 'SUB OFF',
                              color: _subtitlesEnabled ? const Color(0xFF00E5FF) : Colors.white54,
                              onTap: () {
                                setState(() {
                                  _subtitlesEnabled = !_subtitlesEnabled;
                                  if (_subtitlesEnabled) {
                                    _player?.setSubtitleTrack(SubtitleTrack.auto());
                                  } else {
                                    _player?.setSubtitleTrack(SubtitleTrack.no());
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 12),

                            // 7. Love Icon (Favorite)
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
