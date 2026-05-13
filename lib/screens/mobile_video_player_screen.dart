import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';

class MobileVideoPlayerScreen extends StatefulWidget {
  final Channel channel;

  const MobileVideoPlayerScreen({
    Key? key,
    required this.channel,
  }) : super(key: key);

  @override
  State<MobileVideoPlayerScreen> createState() => _MobileVideoPlayerScreenState();
}

class _MobileVideoPlayerScreenState extends State<MobileVideoPlayerScreen> {
  Player? player;
  VideoController? controller;
  
  // Seamless Recovery State
  Player? _stagingPlayer;
  VideoController? _stagingController;

  bool _isLoading = true;
  String? _error;
  Timer? _progressTimer;
  bool _controlsVisible = true;
  Timer? _controlsTimer;

  // Watchdog for stall detection
  DateTime? _lastPositionUpdateTime;
  Duration? _lastPosition;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context);
    try {
      // Create new player instance (Seamless background initialization)
      final newPlayer = Player();
      final newController = VideoController(newPlayer);

      if (player != null) {
        print('🔄 Seamless Recovery: Initiating background player...');
        setState(() {
          _stagingPlayer = newPlayer;
          _stagingController = newController;
        });
      }

      // Smarter Buffering Algorithm
      try {
        final dynamic native = newPlayer.platform;
        final String url = widget.channel.url.toLowerCase();
        
        if (url.contains('.m3u8')) {
          native.setProperty('demuxer-max-bytes', '67108864'); // 64MB
          native.setProperty('cache-secs', '15');
          native.setProperty('hls-bitrate', 'max');
          native.setProperty('hls-reload-mode', 'all');
        } else if (url.contains('.ts') || url.contains('/live/')) {
          native.setProperty('demuxer-max-bytes', '167772160'); // 160MB
          native.setProperty('cache-secs', '60');
        } else if (widget.channel.contentType != ContentType.live) {
          native.setProperty('demuxer-max-bytes', '268435456'); // 256MB
          native.setProperty('cache-secs', '300');
        } else {
          native.setProperty('demuxer-max-bytes', '134217728'); // 128MB
          native.setProperty('cache-secs', '45');
        }

        native.setProperty('demuxer-max-back-bytes', '67108864'); 
        native.setProperty('cache', 'yes');
        native.setProperty('http-reconnect', 'yes');
        native.setProperty('live-auto-range', 'yes');
        native.setProperty('demuxer-lavf-o', 'reconnect_at_eof=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_on_http_error=403,404,5xx,reconnect_delay_max=5');
        native.setProperty('network-timeout', '60');
        native.setProperty('framedrop', 'vo');
        native.setProperty('vd-lavc-fast', 'yes');
        native.setProperty('rtsp-transport', 'tcp');
        native.setProperty('tls-verify', 'no');
        native.setProperty('cookies', 'yes');
      } catch (e) {
        print('Warning: Could not set native properties: $e');
      }

      newPlayer.stream.playing.listen((playing) {
        if (playing && mounted) {
          if (player != null && player != newPlayer) {
             // Wait for texture stabilization
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

      newPlayer.stream.error.listen((error) {
        if (mounted && !_isReconnecting) {
          if (widget.channel.contentType == ContentType.live) {
             _isReconnecting = true;
             _initializePlayer();
          } else {
            setState(() {
              _error = l10n.failedToLoadStream(error.toString());
              _isLoading = false;
            });
          }
        }
      });

      newPlayer.stream.completed.listen((completed) {
        if (completed && mounted && !_isReconnecting) {
          if (widget.channel.contentType == ContentType.live) {
            _isReconnecting = true;
            _initializePlayer(); 
          } else {
            Navigator.of(context).pop();
          }
        }
      });

      newPlayer.stream.position.listen((pos) {
        if (!mounted || widget.channel.contentType != ContentType.live || player != newPlayer) return;

        if (_lastPosition != null && _lastPosition == pos) {
          if (_lastPositionUpdateTime != null && 
              DateTime.now().difference(_lastPositionUpdateTime!).inSeconds > 8 &&
              !_isReconnecting && newPlayer.state.playing) {
            print('⚠️ Seamless Recovery: Stall detected, using background buffer...');
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

      if (widget.channel.contentType != ContentType.live &&
          widget.channel.watchedMilliseconds > 0) {
        await newPlayer.seek(Duration(milliseconds: widget.channel.watchedMilliseconds));
      }

      await DatabaseService.updateChannelPlayCount(widget.channel);
      if (widget.channel.contentType != ContentType.live) _startProgressTimer();
      _hideControlsAfterDelay();
    } catch (e) {
      if (mounted && player == null) {
        setState(() {
          _error = l10n.failedToLoadStream(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _saveWatchProgress();
    });
  }

  void _hideControlsAfterDelay() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _hideControlsAfterDelay();
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controlsTimer?.cancel();
    _saveWatchProgress();
    player?.dispose();
    
    // Restore orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  Future<void> _saveWatchProgress() async {
    if (player == null || widget.channel.contentType == ContentType.live) return;

    final position = player!.state.position;
    final duration = player!.state.duration;

    if (position != Duration.zero && duration != Duration.zero) {
      widget.channel.watchedMilliseconds = position.inMilliseconds;
      widget.channel.totalMilliseconds = duration.inMilliseconds;
      await DatabaseService.isar.writeTxn(() async {
        await DatabaseService.isar.channels.put(widget.channel);
      });
    }
  }

  void _toggleFavorite() async {
    await DatabaseService.toggleFavorite(widget.channel);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: FocusableActionDetector(
        autofocus: true,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _toggleControls();
            return null;
          }),
        },
        onShowFocusHighlight: (val) {},
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // BACKGROUND LAYER (Preparing recovery)
              if (_stagingController != null)
                 Center(child: Video(controller: _stagingController!)),

              // FOREGROUND LAYER (Current or stalled frame)
              Center(
                child: controller != null 
                  ? Video(controller: controller!)
                  : const SizedBox.shrink(),
              ),

              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF5DD3E5))),

              if (_error != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.backButton),
                      ),
                    ],
                  ),
                ),

              // Custom Overlay Controls
              AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _buildControls(l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.channel.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    widget.channel.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: widget.channel.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom Controls
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (widget.channel.contentType != ContentType.live)
                  _buildProgressBar(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                      onPressed: () {
                        if (player != null) {
                          player!.seek(player!.state.position - const Duration(seconds: 10));
                        }
                      },
                    ),
                    const SizedBox(width: 32),
                    if (player != null) StreamBuilder<bool>(
                      stream: player!.stream.playing,
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 64,
                          ),
                          onPressed: () => player?.playOrPause(),
                        );
                      },
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                      onPressed: () {
                        if (player != null) {
                          player!.seek(player!.state.position + const Duration(seconds: 10));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    if (player == null) return const SizedBox.shrink();
    return StreamBuilder<Duration>(
      stream: player!.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player!.state.duration;
        final progress = duration.inMilliseconds > 0 
          ? position.inMilliseconds / duration.inMilliseconds 
          : 0.0;

        return Column(
          children: [
            Slider(
              value: progress.clamp(0.0, 1.0),
              activeColor: const Color(0xFF5DD3E5),
              inactiveColor: Colors.white24,
              onChanged: (val) {
                if (duration.inMilliseconds > 0) {
                  final target = duration * val;
                  player?.seek(target);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
