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
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  bool _isLoading = true;
  String? _error;
  Timer? _progressTimer;
  bool _controlsVisible = true;
  Timer? _controlsTimer;

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
      print('🎬 MediaKit Opening: ${widget.channel.url}');

      // Set up streams before opening
      player.stream.error.listen((error) {
        print('❌ MediaKit Error: $error');
        if (mounted) {
          setState(() {
            _error = l10n.failedToLoadStream(error.toString());
            _isLoading = false;
          });
        }
      });

      player.stream.playing.listen((playing) {
        if (playing && mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });

      player.stream.completed.listen((completed) {
        if (completed && widget.channel.contentType != ContentType.live) {
          Navigator.pop(context);
        }
      });

      // Simple watchdog for loading state
      Timer(const Duration(seconds: 15), () {
        if (mounted && _isLoading && _error == null) {
          setState(() {
            _error = "Playback timed out. The server might be busy or the link is broken.";
            _isLoading = false;
          });
        }
      });

      // Using a standard browser User-Agent to avoid being blocked by some IPTV servers
      // Some servers block default mpv/ffmpeg user agents on mobile devices.
      await player.open(
        Media(
          widget.channel.url,
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
          },
        ),
        play: true,
      );

      // Resume from saved progress if available (only for VOD)
      if (widget.channel.contentType != ContentType.live &&
          widget.channel.watchedMilliseconds > 0) {
        await player.seek(Duration(milliseconds: widget.channel.watchedMilliseconds));
      }

      // Update play count
      await DatabaseService.updateChannelPlayCount(widget.channel);

      // Start progress tracking timer for VOD content
      if (widget.channel.contentType != ContentType.live) {
        _startProgressTimer();
      }

      _hideControlsAfterDelay();
    } catch (e, stackTrace) {
      print('❌ Error initializing player: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
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
    player.dispose();
    
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
    if (widget.channel.contentType == ContentType.live) return;

    final position = player.state.position;
    final duration = player.state.duration;

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
              // MediaKit Video Widget
              Center(
                child: Video(controller: controller),
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
                        onPressed: () => Navigator.pop(context),
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
                  onPressed: () => Navigator.pop(context),
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
                      onPressed: () => player.seek(player.state.position - const Duration(seconds: 10)),
                    ),
                    const SizedBox(width: 32),
                    StreamBuilder<bool>(
                      stream: player.stream.playing,
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 64,
                          ),
                          onPressed: () => player.playOrPause(),
                        );
                      },
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                      onPressed: () => player.seek(player.state.position + const Duration(seconds: 10)),
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
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.state.duration;
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
                final target = duration * val;
                player.seek(target);
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
