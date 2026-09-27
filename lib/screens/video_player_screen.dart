import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel>? playlist;

  const VideoPlayerScreen({
    super.key,
    required this.channel,
    this.playlist,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Player? player;
  VideoController? controller;

  // Seamless Recovery State
  Player? _stagingPlayer;
  VideoController? _stagingController;

  bool _isControlsVisible = true;
  bool _isLoading = true;
  String? _error;
  bool _isFullscreen = false;
  final FocusNode _focusNode = FocusNode();
  Timer? _hideControlsTimer;

  // Watchdog for stall detection
  DateTime? _lastPositionUpdateTime;
  Duration? _lastPosition;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
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
        final String url = widget.channel.url.toLowerCase();

        if (url.contains('.m3u8')) {
          native.setProperty('demuxer-max-bytes', '67108864');
          native.setProperty('cache-secs', '15');
          native.setProperty('hls-bitrate', 'max');
          native.setProperty('hls-reload-mode', 'all');
        } else if (url.contains('.ts') || url.contains('/live/')) {
          native.setProperty('demuxer-max-bytes', '201326592');
          native.setProperty('cache-secs', '120');
        } else if (widget.channel.contentType != ContentType.live) {
          native.setProperty('demuxer-max-bytes', '268435456');
          native.setProperty('cache-secs', '300');
        } else {
          native.setProperty('demuxer-max-bytes', '134217728');
          native.setProperty('cache-secs', '60');
        }

        native.setProperty('demuxer-max-back-bytes', '67108864');
        native.setProperty('cache', 'yes');
        native.setProperty('cache-pause', 'yes');
        native.setProperty('demuxer-readahead-secs', '15');
        native.setProperty('http-reconnect', 'yes');
        native.setProperty('live-auto-range', 'yes');
        native.setProperty('demuxer-lavf-o', 'reconnect_at_eof=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_on_http_error=4xx,5xx,reconnect_delay_max=5');
        native.setProperty('network-timeout', '60');
        native.setProperty('framedrop', 'vo');
        native.setProperty('vd-lavc-fast', 'yes');
        native.setProperty('rtsp-transport', 'tcp');
        native.setProperty('tls-verify', 'no');
        native.setProperty('cookies', 'yes');
      } catch (e) {
        // Native property override warning
      }

      newPlayer.stream.playing.listen((playing) {
        if (playing && mounted) {
          if (player != null && player != newPlayer) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (!mounted) return;
              final oldPlayer = player;
              setState(() {
                player = newPlayer;
                controller = newController;
                _stagingPlayer = null;
                _stagingController = null;
                _isLoading = false;
                _isReconnecting = false;
                _lastPosition = null;
                _lastPositionUpdateTime = DateTime.now();
              });
              oldPlayer?.dispose();
            });
          } else if (player == null) {
            setState(() {
              player = newPlayer;
              controller = newController;
              _isLoading = false;
              _isReconnecting = false;
            });
          }
        }
      });

      newPlayer.stream.position.listen((pos) {
        if (!mounted || widget.channel.contentType != ContentType.live || player != newPlayer) return;

        if (_lastPosition != null && _lastPosition == pos) {
          if (_lastPositionUpdateTime != null &&
              DateTime.now().difference(_lastPositionUpdateTime!).inSeconds > 8 &&
              !_isReconnecting && newPlayer.state.playing) {
            _isReconnecting = true;
            _initializePlayer();
          }
        } else {
          _lastPosition = pos;
          _lastPositionUpdateTime = DateTime.now();
        }
      });

      await newPlayer.open(
        Media(
          widget.channel.url,
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.144 Mobile Safari/537.36 IPTV-Smarters/1.0',
            'Connection': 'keep-alive',
          },
        ),
        play: true,
      );

      newPlayer.setSubtitleTrack(SubtitleTrack.no());

      if (widget.channel.contentType != ContentType.live && widget.channel.watchedMilliseconds > 0) {
        await newPlayer.seek(Duration(milliseconds: widget.channel.watchedMilliseconds));
      }

      await DatabaseService.updateChannelPlayCount(widget.channel);
    } catch (e) {
      if (mounted && player == null) {
        setState(() {
          _error = AppLocalizations.of(context).failedToLoadStream(e.toString());
          _isLoading = false;
        });
      }
    }

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

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _focusNode.dispose();

    if (_isFullscreen && !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.setFullScreen(false);
    }

    if (!kIsWeb && Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    _saveWatchProgress();
    player?.dispose();
    super.dispose();
  }

  Future<void> _saveWatchProgress() async {
    if (player == null) return;
    final duration = player!.state.duration;
    final position = player!.state.position;

    if (duration != null && position != null) {
      widget.channel.watchedMilliseconds = position.inMilliseconds;
      widget.channel.totalMilliseconds = duration.inMilliseconds;
      await DatabaseService.isar.writeTxn(() async {
        await DatabaseService.isar.channels.put(widget.channel);
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || player == null) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space) {
      player!.playOrPause();
      _showControls();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      final currentPosition = player!.state.position;
      player!.seek(currentPosition - const Duration(seconds: 10));
      _showControls();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      final currentPosition = player!.state.position;
      player!.seek(currentPosition + const Duration(seconds: 10));
      _showControls();
    } else if (key == LogicalKeyboardKey.arrowUp) {
      final currentVolume = player!.state.volume;
      player!.setVolume((currentVolume + 10).clamp(0, 100));
      _showControls();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      final currentVolume = player!.state.volume;
      player!.setVolume((currentVolume - 10).clamp(0, 100));
      _showControls();
    } else if (key == LogicalKeyboardKey.keyF || key == LogicalKeyboardKey.f11) {
      _toggleFullscreen();
    } else if (key == LogicalKeyboardKey.escape) {
      if (_isFullscreen) {
        _toggleFullscreen();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });

    if (_isControlsVisible) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _toggleFavorite() async {
    await DatabaseService.toggleFavorite(widget.channel);
    setState(() {});
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

    _showControls();
  }

  void _showAudioTrackDialog() {
    if (player == null) return;
    final l10n = AppLocalizations.of(context);
    final audioTracks = player!.state.tracks.audio;
    final currentTrack = player!.state.track.audio;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1A32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2A4C)),
        ),
        title: Text(l10n.audioTracks, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 360,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: audioTracks.length,
            itemBuilder: (context, index) {
              final track = audioTracks[index];
              final isSelected = track.id == currentTrack.id;
              final trackName = track.title ?? track.language ?? l10n.trackShort(index + 1);

              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white54,
                ),
                title: Text(trackName, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  player?.setAudioTrack(track);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSubtitleTrackDialog() {
    if (player == null) return;
    final l10n = AppLocalizations.of(context);
    final subtitleTracks = player!.state.tracks.subtitle.where((t) =>
      t.id != 'no' && t.id != 'auto' && t.id.isNotEmpty
    ).toList();
    final currentTrack = player!.state.track.subtitle;
    final isDisabled = currentTrack.id == 'no' || currentTrack.id == 'auto' || currentTrack.id.isEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1A32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2A4C)),
        ),
        title: Text(l10n.subtitles, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: Icon(
                  isDisabled ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDisabled ? const Color(0xFF6366F1) : Colors.white54,
                ),
                title: Text(l10n.disabled, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  player?.setSubtitleTrack(SubtitleTrack.no());
                  Navigator.pop(context);
                },
              ),
              ...subtitleTracks.asMap().entries.map((entry) {
                final track = entry.value;
                final isSelected = track.id == currentTrack.id;
                final trackName = track.title ?? track.language ?? l10n.subtitleShort(entry.key + 1);

                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF6366F1) : Colors.white54,
                  ),
                  title: Text(trackName, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    player?.setSubtitleTrack(track);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: MouseRegion(
          onHover: (_) => _showControls(),
          onEnter: (_) => _showControls(),
          child: GestureDetector(
            onTap: _isControlsVisible ? _toggleControls : _showControls,
            child: Stack(
              children: [
                // Video Surface
                if (_stagingController != null)
                  SizedBox.expand(
                    child: Video(controller: _stagingController!, controls: NoVideoControls),
                  ),

                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 64),
                                const SizedBox(height: 16),
                                Text(_error!, style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          )
                        : SizedBox.expand(
                            child: controller != null
                                ? Video(controller: controller!, controls: NoVideoControls)
                                : const SizedBox.shrink(),
                          ),

                // Top Header (Only shown when NOT in full screen mode)
                if (!_isFullscreen)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !_isControlsVisible,
                      child: AnimatedOpacity(
                        opacity: _isControlsVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                            ),
                          ),
                          child: SafeArea(
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.channel.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      if (widget.channel.group != null)
                                        Text(
                                          widget.channel.group!,
                                          style: const TextStyle(color: Color(0xFF8F92A9), fontSize: 12),
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
                  ),

                // Bottom Ribbon Media Controls (Auto-hides in 3s)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_isControlsVisible,
                    child: AnimatedOpacity(
                      opacity: _isControlsVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Seekbar & Time labels
                              if (player != null)
                                StreamBuilder<Duration>(
                                  stream: player!.stream.position,
                                  builder: (context, positionSnapshot) {
                                    return StreamBuilder<Duration>(
                                      stream: player!.stream.duration,
                                      builder: (context, durationSnapshot) {
                                        final pos = positionSnapshot.data ?? Duration.zero;
                                        final dur = durationSnapshot.data ?? Duration.zero;
                                        final progress = dur.inMilliseconds > 0
                                            ? pos.inMilliseconds / dur.inMilliseconds
                                            : 0.0;

                                        return Row(
                                          children: [
                                            Text(
                                              _formatDuration(pos),
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                            Expanded(
                                              child: Slider(
                                                value: progress.clamp(0.0, 1.0),
                                                activeColor: const Color(0xFF6366F1),
                                                inactiveColor: Colors.white24,
                                                onChanged: (val) {
                                                  final seekPos = Duration(milliseconds: (val * dur.inMilliseconds).round());
                                                  player?.seek(seekPos);
                                                },
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(dur),
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),

                              // Control Ribbon Buttons Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Playback Buttons
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.replay_10, color: Colors.white),
                                        onPressed: () {
                                          if (player != null) {
                                            player!.seek(player!.state.position - const Duration(seconds: 10));
                                          }
                                        },
                                      ),
                                      if (player != null)
                                        StreamBuilder<bool>(
                                          stream: player!.stream.playing,
                                          builder: (context, snapshot) {
                                            final isPlaying = snapshot.data ?? false;
                                            return IconButton(
                                              icon: Icon(
                                                isPlaying ? Icons.pause_circle : Icons.play_circle,
                                                color: const Color(0xFF6366F1),
                                                size: 38,
                                              ),
                                              onPressed: () => player?.playOrPause(),
                                            );
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.forward_10, color: Colors.white),
                                        onPressed: () {
                                          if (player != null) {
                                            player!.seek(player!.state.position + const Duration(seconds: 10));
                                          }
                                        },
                                      ),
                                    ],
                                  ),

                                  // Volume Slider
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
                                              size: 20,
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: Slider(
                                                value: vol.clamp(0.0, 100.0),
                                                min: 0,
                                                max: 100,
                                                activeColor: const Color(0xFF6366F1),
                                                inactiveColor: Colors.white24,
                                                onChanged: (v) => player?.setVolume(v),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),

                                  // Utility Controls
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
                                        tooltip: l10n.audioTracks,
                                        onPressed: _showAudioTrackDialog,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.subtitles, color: Colors.white, size: 20),
                                        tooltip: l10n.subtitles,
                                        onPressed: _showSubtitleTrackDialog,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          widget.channel.isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: widget.channel.isFavorite ? const Color(0xFFE53935) : Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _toggleFavorite,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        tooltip: _isFullscreen ? l10n.exitFullscreenTooltip : l10n.fullscreenTooltip,
                                        onPressed: _toggleFullscreen,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
