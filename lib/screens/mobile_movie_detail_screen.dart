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
import 'mobile_video_player_screen.dart';

class MobileMovieDetailScreen extends StatefulWidget {
  final Channel movie;
  const MobileMovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  State<MobileMovieDetailScreen> createState() => _MobileMovieDetailScreenState();
}

class _MobileMovieDetailScreenState extends State<MobileMovieDetailScreen> {
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
      MaterialPageRoute(builder: (context) => MobileVideoPlayerScreen(channel: widget.movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(size),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildMainActions(l10n),
                  const SizedBox(height: 32),
                  _buildInfoSection('Plot', _metadata?.plot ?? widget.movie.description ?? 'No description available.'),
                  if (_metadata?.cast != null) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection('Cast', _metadata!.cast!),
                  ],
                  if (_metadata?.director != null) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection('Director', _metadata!.director!),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Size size) {
    final backdrop = _metadata?.backdropUrl ?? widget.movie.logo;
    return SliverAppBar(
      expandedHeight: size.height * 0.4,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1A),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdrop != null)
              Image.network(backdrop, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    const Color(0xFF0F0F1A).withOpacity(0.8),
                    const Color(0xFF0F0F1A),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.movie.name,
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        if (_metadata?.releaseDate != null)
          Text(_metadata!.releaseDate!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(
            (_metadata?.rating ?? widget.movie.rating).toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 24),
          if (_metadata?.genre != null)
            Expanded(
              child: Text(
                _metadata!.genre!,
                style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainActions(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _playMovie,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 30),
            label: Text(l10n.playButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
          child: IconButton(
            onPressed: () {}, // Favorite
            icon: const Icon(Icons.favorite_outline_rounded, color: Colors.white),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, height: 1.6),
        ),
      ],
    );
  }
}
