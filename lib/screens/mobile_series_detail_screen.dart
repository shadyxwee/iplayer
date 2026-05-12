import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/channel.dart';
import '../models/series.dart';
import '../models/series_item.dart';
import '../models/media_metadata.dart';
import '../services/metadata_service.dart';
import '../services/database_service.dart';
import '../services/xtream_service.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'android_video_player_screen.dart';

class MobileSeriesDetailScreen extends StatefulWidget {
  final Channel series;
  final List<Channel> episodes;
  final String seriesTitle;

  const MobileSeriesDetailScreen({
    Key? key,
    required this.series,
    required this.episodes,
    required this.seriesTitle,
  }) : super(key: key);

  @override
  State<MobileSeriesDetailScreen> createState() => _MobileSeriesDetailScreenState();
}

class _MobileSeriesDetailScreenState extends State<MobileSeriesDetailScreen> {
  MediaMetadata? _metadata;
  Map<String, dynamic>? _seriesData;
  bool _isLoading = true;
  String? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoading = true);
    
    XtreamService? xtreamService;
    final playlistId = widget.series.playlistId;
    if (playlistId != null) {
      final playlist = await DatabaseService.getPlaylistById(playlistId);
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
    if (xtreamService != null) {
       final seriesId = widget.series.tvgId ?? 0;
       final seriesItem = SeriesItem(
         seriesId: seriesId,
         name: widget.seriesTitle,
         cover: widget.series.logo,
         rating: widget.series.rating,
       );
       meta = await metadataService.getSeriesMetadata(seriesItem);
       
       try {
         final info = await xtreamService.getSeriesInfo(seriesId);
         if (info['success'] == true && info['data'] != null) {
           _seriesData = info['data'];
           final dynamic seasonSource = _seriesData?['seasons'];
           List<String> seasonsList = [];
           if (seasonSource is List) {
             seasonsList = seasonSource.map((s) => s['season_number']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
           }
           if (seasonsList.isNotEmpty) {
             _selectedSeason = seasonsList.first;
           }
         }
       } catch (e) {
         debugPrint('Error loading series info: $e');
       }
    } else {
       meta = await MetadataService.resolveChannelMetadata(widget.seriesTitle, false);
    }

    if (mounted) {
      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    }
  }

  void _playEpisode(Map<String, dynamic> episodeData) {
    final playlistId = widget.series.playlistId;
    if (playlistId == null) return;

    final channel = Channel();
    channel.name = (episodeData['title'] ?? 'Episode').toString();
    channel.contentType = ContentType.series;
    channel.playlistId = playlistId;
    
    if (episodeData['url'] != null) {
      channel.url = episodeData['url'];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AndroidVideoPlayerScreen(channel: channel)),
      );
      return;
    }

    DatabaseService.getPlaylistById(playlistId).then((playlist) {
      if (playlist != null && mounted) {
        final ext = episodeData['container_extension'] ?? 'mp4';
        final streamId = episodeData['id'] ?? episodeData['stream_id'];
        if (streamId == null) return;
        channel.url = '${playlist.url}/series/${playlist.username}/${playlist.password}/$streamId.$ext';
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AndroidVideoPlayerScreen(channel: channel)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    final dynamic episodesRaw = _seriesData?['episodes'];
    List currentEpisodes = [];
    if (_selectedSeason != null && episodesRaw != null) {
      if (episodesRaw is Map) {
        final episodesForSeason = episodesRaw[_selectedSeason!] ?? episodesRaw[int.tryParse(_selectedSeason!)];
        if (episodesForSeason is List) currentEpisodes = episodesForSeason;
      }
    } else if (widget.episodes.isNotEmpty) {
       currentEpisodes = widget.episodes.map((e) => {
         'title': e.name,
         'url': e.url,
         'episode_num': widget.episodes.indexOf(e) + 1,
       }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(size),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(l10n),
                  _buildStatsAndActions(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 32),
                  _buildSeasonsRow(),
                  _buildEpisodesList(currentEpisodes, l10n),
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
    final backdrop = _metadata?.backdropUrl ?? widget.series.logo;
    return SliverAppBar(
      expandedHeight: size.height * 0.35,
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
                    Colors.black.withOpacity(0.3),
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.seriesTitle,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        if (_metadata?.genre != null)
          Text(_metadata!.genre!, style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatsAndActions() {
    final rating = _metadata?.rating ?? widget.series.rating;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          _buildStatItem(Icons.star_rounded, rating.toStringAsFixed(1), Colors.amber),
          const SizedBox(width: 16),
          _buildStatItem(Icons.movie_rounded, widget.episodes.length.toString(), Colors.blue),
          const Spacer(),
          IconButton(
            onPressed: () {}, // Favorite logic
            icon: const Icon(Icons.favorite_outline_rounded, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {}, // Share logic
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildDescription() {
    final plot = _metadata?.plot ?? widget.series.description;
    if (plot == null || plot.isEmpty) return const SizedBox();
    return Text(
      plot,
      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSeasonsRow() {
    final dynamic seasonsRaw = _seriesData?['seasons'];
    if (seasonsRaw == null || seasonsRaw is! List) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Seasons', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (seasonsRaw as List).length,
            itemBuilder: (context, index) {
              final sNum = (seasonsRaw[index]['season_number'] ?? index + 1).toString();
              final isSelected = _selectedSeason == sNum;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('S$sNum'),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedSeason = val ? sNum : null),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                  labelStyle: TextStyle(color: isSelected ? const Color(0xFF8B5CF6) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEpisodesList(List currentEpisodes, AppLocalizations l10n) {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF8B5CF6))));
    if (currentEpisodes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Episodes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentEpisodes.length,
          itemBuilder: (context, index) {
            final episode = currentEpisodes[index];
            final epNum = episode['episode_num'] ?? (index + 1);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.play_arrow_rounded, color: Color(0xFF8B5CF6), size: 28)),
                ),
                title: Text('Episode $epNum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(episode['title'] ?? 'Play Episode', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                trailing: const Icon(Icons.download_rounded, color: Colors.white24, size: 20),
                onTap: () => _playEpisode(episode),
              ),
            );
          },
        ),
      ],
    );
  }
}
