import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../services/m3u_parser.dart';
import '../l10n/app_localizations.dart';
import '../widgets/smooth_page_route.dart';
import 'epg_screen.dart';

class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  Map<String, Map<String, List<Channel>>> _hierarchy = {};
  String? _selectedParentCategory;
  String? _selectedSubCategory;
  String _searchQuery = '';
  Channel? _selectedChannel;

  // Video player
  Player? player;
  VideoController? controller;

  // Seamless Recovery State
  Player? _stagingPlayer;
  VideoController? _stagingController;

  bool _isPlayerInitialized = false;
  bool _isFullscreen = false;
  bool _isOverlayVisible = true;
  Timer? _hideOverlayTimer;

  // Watchdog for stall detection
  DateTime? _lastPositionUpdateTime;
  Duration? _lastPosition;
  bool _isReconnecting = false;
  int _recoveryLevel = 0;
  Timer? _stallWatchdog;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _startStallWatchdog();
  }

  void _startStallWatchdog() {
    _stallWatchdog?.cancel();
    _stallWatchdog = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _selectedChannel == null || player == null || _isReconnecting) return;

      final pos = player!.state.position;
      final isPlaying = player!.state.playing;

      if (isPlaying && _lastPosition != null && _lastPosition == pos) {
        if (_lastPositionUpdateTime != null &&
            DateTime.now().difference(_lastPositionUpdateTime!).inSeconds > 15) {
          _triggerRecovery();
        }
      } else {
        _lastPosition = pos;
        _lastPositionUpdateTime = DateTime.now();
      }
    });
  }

  void _triggerRecovery() async {
    if (_isReconnecting || _selectedChannel == null) return;

    _isReconnecting = true;
    _recoveryLevel++;

    if (_recoveryLevel <= 2) {
      try {
        await _openMedia(player!, _selectedChannel!);
        _isReconnecting = false;
      } catch (e) {
        _isReconnecting = false;
      }
    } else {
      _playChannel(_selectedChannel!);
    }
  }

  void _startHideOverlayTimer() {
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isOverlayVisible) {
        setState(() {
          _isOverlayVisible = false;
        });
      }
    });
  }

  void _showOverlay() {
    if (!_isOverlayVisible) {
      setState(() {
        _isOverlayVisible = true;
      });
    }
    _startHideOverlayTimer();
  }

  void _toggleOverlay() {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
    });
    if (_isOverlayVisible) {
      _startHideOverlayTimer();
    } else {
      _hideOverlayTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _stallWatchdog?.cancel();
    _hideOverlayTimer?.cancel();
    _searchController.dispose();
    player?.dispose();
    _stagingPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    final allChannels = await DatabaseService.getAllChannels();
    final liveChannels = allChannels
        .where((c) => c.contentType == ContentType.live)
        .toList();

    final hierarchy = M3UParser.groupChannelsHierarchical(liveChannels);

    setState(() {
      _allChannels = liveChannels;
      _filteredChannels = liveChannels;
      _hierarchy = hierarchy;

      if (liveChannels.isNotEmpty) {
        _playChannel(liveChannels.first);
      }
    });
  }

  void _filterChannels() {
    List<Channel> filtered = _allChannels;

    if (_selectedParentCategory != null) {
      if (_selectedSubCategory != null && _selectedSubCategory != 'All') {
        filtered = filtered.where((c) {
          final g = (c.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          final sub = _selectedSubCategory!.toLowerCase();
          return g.contains(p) && g.contains(sub);
        }).toList();
      } else {
        filtered = filtered.where((c) {
          final g = (c.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          return g.startsWith(p) || g == p;
        }).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredChannels = filtered;
    });
  }

  Future<void> _playChannel(Channel channel) async {
    final newPlayer = Player();
    final newController = VideoController(newPlayer);

    if (player != null) {
      setState(() {
        _stagingPlayer = newPlayer;
        _stagingController = newController;
      });
    }

    try {
      final dynamic native = newPlayer.platform;
      final String url = channel.url.toLowerCase();

      native.setProperty('keep-open', 'yes');
      native.setProperty('force-window', 'yes');
      native.setProperty('hwdec', 'no');
      native.setProperty('msg-level', 'all=warn,ffmpeg=error,ffmpeg/video=error');

      if (url.contains('.m3u8')) {
        native.setProperty('demuxer-max-bytes', '16777216');
        native.setProperty('cache-secs', '6');
        native.setProperty('hls-live-edge', '1');
        native.setProperty('hls-bitrate', 'max');
        native.setProperty('hls-reload-mode', 'all');
      } else if (url.contains('.ts') || url.contains('/live/')) {
        native.setProperty('demuxer-max-bytes', '67108864');
        native.setProperty('cache-secs', '20');
        native.setProperty('stream-buffer-size', '512k');
      } else {
        native.setProperty('demuxer-max-bytes', '134217728');
        native.setProperty('cache-secs', '45');
      }

      native.setProperty('demuxer-max-back-bytes', '0');
      native.setProperty('cache', 'yes');
      native.setProperty('cache-pause', 'yes');
      native.setProperty('demuxer-readahead-secs', '15');
      native.setProperty('http-reconnect', 'yes');
      native.setProperty('live-auto-range', 'yes');
      native.setProperty('demuxer-lavf-o', 'reconnect_at_eof=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_on_http_error=4xx,5xx,reconnect_delay_max=2');
      native.setProperty('network-timeout', '20');
      native.setProperty('framedrop', 'vo');
      native.setProperty('vd-lavc-threads', '4');
      native.setProperty('mc', '0');
    } catch (e) {
      // Native override fallback
    }

    newPlayer.stream.playing.listen((playing) {
      if (playing && mounted) {
        if (player != null && player != newPlayer) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            final oldPlayer = player;
            setState(() {
              _selectedChannel = channel;
              player = newPlayer;
              controller = newController;
              _stagingPlayer = null;
              _stagingController = null;
              _isPlayerInitialized = true;
              _isReconnecting = false;
              _recoveryLevel = 0;
              _lastPositionUpdateTime = DateTime.now();
            });
            Future.delayed(const Duration(seconds: 1), () => oldPlayer?.dispose());
          });
        } else if (player == null) {
          setState(() {
            _selectedChannel = channel;
            player = newPlayer;
            controller = newController;
            _isPlayerInitialized = true;
            _isReconnecting = false;
            _recoveryLevel = 0;
          });
        }
      }
    });

    await _openMedia(newPlayer, channel);
  }

  Future<void> _openMedia(Player p, Channel channel) async {
    try {
      await p.open(
        Media(
          channel.url,
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.144 Mobile Safari/537.36 IPTV-Smarters/1.0',
            'Connection': 'keep-alive',
            'Accept': '*/*',
          },
        ),
        play: true,
      );
      await DatabaseService.updateChannelPlayCount(channel);
    } catch (e) {
      // Stream error
    }
  }

  void _playNextChannel() {
    if (_filteredChannels.isEmpty || _selectedChannel == null) return;
    final currentIndex = _filteredChannels.indexWhere((c) => c.id == _selectedChannel!.id);
    if (currentIndex != -1 && currentIndex < _filteredChannels.length - 1) {
      _playChannel(_filteredChannels[currentIndex + 1]);
    }
  }

  void _playPreviousChannel() {
    if (_filteredChannels.isEmpty || _selectedChannel == null) return;
    final currentIndex = _filteredChannels.indexWhere((c) => c.id == _selectedChannel!.id);
    if (currentIndex > 0) {
      _playChannel(_filteredChannels[currentIndex - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF111022),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF17152F),
              Color(0xFF0D0C1B),
            ],
          ),
        ),
        child: SafeArea(
          child: _isFullscreen
              ? _buildFullscreenPlayer(l10n)
              : Row(
                  children: [
                    // Left Sidebar - Categories
                    _buildCategorySidebar(l10n),

                    // Middle - Channel List
                    _buildChannelListSection(l10n),

                    // Right Side - Video Player Window
                    Expanded(child: _buildInlineVideoPlayer(l10n)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategorySidebar(AppLocalizations l10n) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1A32),
        border: Border(
          right: BorderSide(color: Color(0xFF2C2A4C), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top Header & Back Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIconButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.backButton,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.liveTV,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              itemCount: _hierarchy.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedParentCategory == null;
                  return _buildCategoryTile(
                    title: l10n.all,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedParentCategory = null;
                        _selectedSubCategory = null;
                      });
                      _filterChannels();
                    },
                  );
                }

                final parent = _hierarchy.keys.elementAt(index - 1);
                final subs = _hierarchy[parent]!;
                final isParentSelected = _selectedParentCategory == parent;

                return Column(
                  children: [
                    _buildCategoryTile(
                      title: parent,
                      isSelected: isParentSelected,
                      hasSub: subs.length > 1,
                      onTap: () {
                        setState(() {
                          if (_selectedParentCategory == parent && _selectedSubCategory == 'All') {
                            _selectedParentCategory = null;
                            _selectedSubCategory = null;
                          } else {
                            _selectedParentCategory = parent;
                            _selectedSubCategory = 'All';
                          }
                        });
                        _filterChannels();
                      },
                    ),

                    if (isParentSelected && subs.length > 1)
                      ...subs.keys.map((sub) {
                        final isSubSelected = _selectedSubCategory == sub;
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildCategoryTile(
                            title: sub,
                            isSelected: isSubSelected,
                            isSub: true,
                            onTap: () {
                              setState(() {
                                _selectedSubCategory = sub;
                              });
                              _filterChannels();
                            },
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasSub = false,
    bool isSub = false,
  }) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        final active = isSelected || isHovered;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSub ? 10 : 14,
              ),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF23223F) : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: active ? const Color(0xFF6366F1) : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF8F92A9),
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        fontSize: isSub ? 13 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasSub)
                    Icon(
                      isSelected ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      size: 18,
                      color: active ? const Color(0xFF818CF8) : const Color(0xFF8F92A9),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelListSection(AppLocalizations l10n) {
    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Color(0xFF16152A),
        border: Border(
          right: BorderSide(color: Color(0xFF2C2A4C), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top Search & Utility Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1B1A32),
              border: Border(bottom: BorderSide(color: Color(0xFF2C2A4C), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1D34),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E2B52)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF8F92A9), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: l10n.search,
                              hintStyle: const TextStyle(color: Color(0xFF8F92A9), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                              _filterChannels();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.calendar_month,
                  tooltip: l10n.epgGuide,
                  onTap: () {
                    Navigator.push(context, SmoothPageRoute(child: const EpgScreen()));
                  },
                ),
                const SizedBox(width: 6),
                _buildIconButton(
                  icon: Icons.refresh,
                  tooltip: l10n.refresh,
                  onTap: _loadChannels,
                ),
              ],
            ),
          ),

          // Channel List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredChannels.length,
              itemBuilder: (context, index) {
                final channel = _filteredChannels[index];
                final isSelected = _selectedChannel?.id == channel.id;
                bool isHovered = false;

                return StatefulBuilder(
                  builder: (context, setState) {
                    final active = isSelected || isHovered;

                    return MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: () => _playChannel(channel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF23223F) : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: active ? const Color(0xFF6366F1) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Number Badge
                              Container(
                                width: 32,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFF6366F1) : const Color(0xFF1E1D34),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: active ? Colors.white : const Color(0xFF8F92A9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Channel Logo
                              if (channel.logo != null && channel.logo!.isNotEmpty)
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Image.network(
                                    channel.logo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Color(0xFF8F92A9), size: 18),
                                  ),
                                ),

                              // Channel Title & Group
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      channel.name,
                                      style: TextStyle(
                                        color: active ? Colors.white : const Color(0xFFCBD5E1),
                                        fontSize: 13,
                                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (channel.group != null)
                                      Text(
                                        channel.group!,
                                        style: const TextStyle(
                                          color: Color(0xFF8F92A9),
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineVideoPlayer(AppLocalizations l10n) {
    return Container(
      color: Colors.black,
      child: _selectedChannel == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tv, size: 64, color: Color(0xFF8F92A9)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.selectChannel,
                    style: const TextStyle(color: Color(0xFF8F92A9), fontSize: 18),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top Info Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: const Color(0xFF1B1A32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedChannel!.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedChannel!.group != null)
                              Text(
                                _selectedChannel!.group!,
                                style: const TextStyle(color: Color(0xFF8F92A9), fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _selectedChannel!.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _selectedChannel!.isFavorite ? const Color(0xFFE53935) : Colors.white,
                        ),
                        onPressed: () async {
                          await DatabaseService.toggleFavorite(_selectedChannel!);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isFullscreen = true;
                            _isOverlayVisible = true;
                          });
                          _startHideOverlayTimer();
                        },
                      ),
                    ],
                  ),
                ),

                // Video Surface
                Expanded(
                  child: Stack(
                    children: [
                      if (_stagingController != null)
                        SizedBox.expand(
                          child: Video(controller: _stagingController!, controls: NoVideoControls),
                        ),
                      controller != null && _isPlayerInitialized
                          ? SizedBox.expand(
                              child: Video(controller: controller!, controls: NoVideoControls),
                            )
                          : const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFullscreenPlayer(AppLocalizations l10n) {
    return MouseRegion(
      onHover: (_) => _showOverlay(),
      onEnter: (_) => _showOverlay(),
      child: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            SizedBox.expand(
              child: controller != null
                  ? Video(controller: controller!, controls: NoVideoControls)
                  : const SizedBox.shrink(),
            ),

            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_isOverlayVisible,
                child: AnimatedOpacity(
                  opacity: _isOverlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Row(
                            children: [
                              Text(
                                _selectedChannel?.name ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                                tooltip: l10n.exitFullscreenTooltip,
                                onPressed: () {
                                  setState(() {
                                    _isFullscreen = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMediaControlButton(
                              icon: Icons.skip_previous,
                              size: 32,
                              onTap: _playPreviousChannel,
                            ),
                            const SizedBox(width: 24),
                            if (player != null)
                              StreamBuilder<bool>(
                                stream: player!.stream.playing,
                                builder: (context, snapshot) {
                                  final isPlaying = snapshot.data ?? false;
                                  return _buildMediaControlButton(
                                    icon: isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 44,
                                    isPrimary: true,
                                    onTap: () {
                                      player?.playOrPause();
                                    },
                                  );
                                },
                              ),
                            const SizedBox(width: 24),
                            _buildMediaControlButton(
                              icon: Icons.skip_next,
                              size: 32,
                              onTap: _playNextChannel,
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: Row(
                            children: [
                              if (player != null)
                                StreamBuilder<double>(
                                  stream: player!.stream.volume,
                                  builder: (context, snapshot) {
                                    final vol = snapshot.data ?? 100.0;
                                    return Row(
                                      children: [
                                        Icon(
                                          vol == 0 ? Icons.volume_off : Icons.volume_up,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Slider(
                                            value: vol.clamp(0.0, 100.0),
                                            min: 0,
                                            max: 100,
                                            activeColor: const Color(0xFF6366F1),
                                            inactiveColor: Colors.white30,
                                            onChanged: (v) => player?.setVolume(v),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  _selectedChannel?.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                                  color: _selectedChannel?.isFavorite == true ? const Color(0xFFE53935) : Colors.white,
                                ),
                                onPressed: () async {
                                  if (_selectedChannel != null) {
                                    await DatabaseService.toggleFavorite(_selectedChannel!);
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.all(isPrimary ? 16 : 12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? const Color(0xFF6366F1)
                    : (isHovered ? const Color(0xFF282645) : Colors.black45),
                shape: BoxShape.circle,
                border: Border.all(color: isHovered ? const Color(0xFF818CF8) : Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: size),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: tooltip,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isHovered ? const Color(0xFF282645) : const Color(0xFF1E1D34),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isHovered ? const Color(0xFF6366F1) : const Color(0xFF2E2B52),
                  ),
                ),
                child: Icon(icon, color: isHovered ? Colors.white : const Color(0xFF8F92A9), size: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}
