import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/channel.dart';
import '../models/media_metadata.dart';
import '../models/vod_item.dart';
import '../services/metadata_service.dart';
import '../services/database_service.dart';
import '../services/xtream_service.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'video_player_screen.dart';
import 'mobile_video_player_screen.dart';
import 'dart:io' show Platform;

class MovieDetailScreen extends StatefulWidget {
  final Channel movie;
  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  MediaMetadata? _metadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoading = true);
    
    XtreamService? xtreamService;
    
    // Check if the movie is from an Xtream playlist
    if (widget.movie.playlistId != null) {
      final playlist = await DatabaseService.getPlaylistById(widget.movie.playlistId!);
      if (playlist != null && playlist.isXtreamCodes) {
        xtreamService = XtreamService(
          baseUrl: playlist.url,
          username: playlist.username!,
          password: playlist.password!,
        );
      }
    }

    final metadataService = MetadataService(xtreamService: xtreamService);
    
    MediaMetadata meta;
    if (xtreamService != null && widget.movie.tvgId != null) {
       // Create a temporary VodItem for metadata service
       final vodItem = VodItem(
         streamId: widget.movie.tvgId!,
         name: widget.movie.name,
         streamIcon: widget.movie.logo,
         rating: widget.movie.rating,
         plot: widget.movie.description,
         baseUrl: xtreamService.baseUrl,
         username: xtreamService.username,
         password: xtreamService.password,
       );
       meta = await metadataService.getMovieMetadata(vodItem);
    } else {
       meta = await MetadataService.resolveChannelMetadata(widget.movie.name, true);
    }

    if (mounted) {
      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    }
  }

  void _playMovie() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Platform.isAndroid
            ? MobileVideoPlayerScreen(channel: widget.movie)
            : VideoPlayerScreen(channel: widget.movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: size.height * 0.4,
            pinned: true,
            backgroundColor: theme.backgroundPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop
                  if (_metadata?.backdropUrl != null || widget.movie.logo != null)
                    Image.network(
                      _metadata?.backdropUrl ?? widget.movie.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: theme.backgroundSecondary),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.backgroundPrimary.withOpacity(0.8),
                          theme.backgroundPrimary,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      if (_metadata?.posterUrl != null || widget.movie.logo != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _metadata?.posterUrl ?? widget.movie.logo!,
                            width: 150,
                            height: 225,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 150, height: 225, color: theme.backgroundTertiary),
                          ),
                        ),
                      const SizedBox(width: 24),
                      // Main info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.name,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_metadata?.releaseDate != null)
                              Text(
                                _metadata!.releaseDate!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6), 
                                    fontSize: 16),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if ((_metadata?.rating ?? widget.movie.rating) > 0) ...[
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    (_metadata?.rating ?? widget.movie.rating).toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.white, 
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (_metadata?.genre != null)
                                  Expanded(
                                    child: Text(
                                      _metadata!.genre!,
                                      style: TextStyle(color: theme.accentPrimary, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _playMovie,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.accentPrimary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.play_arrow, size: 28),
                              label: Text(l10n.playButton, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Plot
                  Text(
                    'Plot',
                    style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                     const CircularProgressIndicator()
                  else
                    Text(
                      _metadata?.plot ?? widget.movie.description ?? 'No description available.',
                      style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white.withOpacity(0.8), 
                          height: 1.6),
                    ),
                  const SizedBox(height: 32),
                  // Cast & Director
                  if (_metadata?.cast != null) ...[
                    Text(
                      'Cast',
                      style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _metadata!.cast!,
                      style: TextStyle(
                          fontSize: 15, 
                          color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_metadata?.director != null) ...[
                    Text(
                      'Director',
                      style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _metadata!.director!,
                      style: TextStyle(
                          fontSize: 15, 
                          color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
