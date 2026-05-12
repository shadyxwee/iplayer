import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/series.dart';
import '../models/series_item.dart';
import '../models/media_metadata.dart';
import '../models/channel.dart';
import '../services/metadata_service.dart';
import '../services/database_service.dart';
import '../services/xtream_service.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'video_player_screen.dart';
import 'mobile_video_player_screen.dart';
import 'dart:io' show Platform;

class SeriesDetailScreen extends StatefulWidget {
  final Series series;
  const SeriesDetailScreen({Key? key, required this.series}) : super(key: key);

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
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
       final seriesId = int.tryParse(widget.series.id ?? '0') ?? 0;
       final seriesItem = SeriesItem(
         seriesId: seriesId,
         name: widget.series.name,
         cover: widget.series.cover,
         rating: widget.series.rating ?? 0.0,
         plot: widget.series.plot,
       );
       meta = await metadataService.getSeriesMetadata(seriesItem);
       
       try {
         final info = await xtreamService.getSeriesInfo(seriesId).timeout(const Duration(seconds: 15));
         if (info['success'] == true && info['data'] != null) {
           _seriesData = info['data'];
           // Normalize seasons: handle both List and potential Map versions
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
         print('Error loading series info: $e');
       }
    } else {
       meta = await MetadataService.resolveChannelMetadata(widget.series.name, false);
    }

    if (mounted) {
      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    }
  }

  void _playEpisode(Map<String, dynamic> episode) {
    final playlistId = widget.series.playlistId;
    if (playlistId == null) return;

    final channel = Channel();
    channel.name = (episode['title'] ?? 'Episode').toString();
    channel.contentType = ContentType.series;
    channel.playlistId = playlistId;
    
    // If it's a direct URL (M3U parsed series)
    if (episode['url'] != null) {
      channel.url = episode['url'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Platform.isAndroid
              ? MobileVideoPlayerScreen(channel: channel)
              : VideoPlayerScreen(channel: channel),
        ),
      );
      return;
    }

    DatabaseService.getPlaylistById(playlistId).then((playlist) {
      if (playlist != null && mounted) {
        final ext = episode['container_extension'] ?? 'mp4';
        final streamId = episode['id'] ?? episode['stream_id'];
        if (streamId == null) return;
        
        channel.url = '${playlist.url}/series/${playlist.username}/${playlist.password}/$streamId.$ext';
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Platform.isAndroid
                ? MobileVideoPlayerScreen(channel: channel)
                : VideoPlayerScreen(channel: channel),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    // Normalizing seasons and episodes
    final dynamic seasonsRaw = _seriesData?['seasons'];
    List seasons = [];
    if (seasonsRaw is List) {
      seasons = seasonsRaw;
    } else if (widget.series.seasons.isNotEmpty) {
      seasons = widget.series.seasons.map((s) => {'season_number': s.seasonNumber}).toList();
    }
    
    if (_selectedSeason == null && seasons.isNotEmpty) {
      _selectedSeason = (seasons.first['season_number'] ?? '1').toString();
    }

    final dynamic episodesRaw = _seriesData?['episodes'];
    List currentEpisodes = [];
    if (_selectedSeason != null) {
      if (episodesRaw != null) {
        if (episodesRaw is Map) {
          // Map based structure (Standard Xtream)
          final seasonKey = _selectedSeason!;
          final episodesForSeason = episodesRaw[seasonKey] ?? episodesRaw[int.tryParse(seasonKey)];
          if (episodesForSeason is List) {
            currentEpisodes = episodesForSeason;
          }
        } else if (episodesRaw is List) {
          // Flat list structure (Some providers)
          currentEpisodes = episodesRaw.where((ep) {
            final sNum = (ep['season'] ?? ep['season_number'] ?? '1').toString();
            return sNum == _selectedSeason;
          }).toList();
        }
      } else if (widget.series.seasons.isNotEmpty) {
        // Fallback to local episodes (M3U)
        try {
          final season = widget.series.seasons.firstWhere(
            (s) => s.seasonNumber.toString() == _selectedSeason,
            orElse: () => widget.series.seasons.first,
          );
          currentEpisodes = season.episodes.map((e) => {
            'title': e.name,
            'url': e.url,
            'episode_num': e.episodeNumber,
          }).toList();
        } catch (_) {}
      }
    }

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
                  if (_metadata?.backdropUrl != null || widget.series.cover != null)
                    Image.network(
                      _metadata?.backdropUrl ?? widget.series.cover ?? '',
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
                      if (_metadata?.posterUrl != null || widget.series.cover != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _metadata?.posterUrl ?? widget.series.cover ?? '',
                            width: 130,
                            height: 195,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 130, height: 195, color: theme.backgroundSecondary, child: const Icon(Icons.movie, size: 40, color: Colors.white24)),
                          ),
                        ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.series.name,
                              style: TextStyle(
                                fontSize: 28, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if ((_metadata?.rating ?? widget.series.rating ?? 0.0) > 0) ...[
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    (_metadata?.rating ?? widget.series.rating ?? 0.0).toStringAsFixed(1),
                                    style: TextStyle(
                                        color: Colors.white, 
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                                const SizedBox(width: 16),
                                if (_metadata?.genre != null)
                                  Expanded(child: Text(_metadata!.genre!, style: TextStyle(color: theme.accentPrimary), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_metadata?.plot != null || widget.series.plot != null)
                              Text(
                                _metadata?.plot ?? widget.series.plot ?? '',
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withOpacity(0.7)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Seasons Row
                  if (seasons.isNotEmpty) ...[
                    Text('Seasons', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: seasons.length,
                        itemBuilder: (context, index) {
                          final seasonNum = (seasons[index]['season_number'] ?? index + 1).toString();
                          final isSelected = _selectedSeason == seasonNum;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              label: Text('Season $seasonNum'),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedSeason = seasonNum);
                              },
                              backgroundColor: theme.backgroundTertiary,
                              selectedColor: theme.accentPrimary,
                              labelStyle: TextStyle(color: isSelected ? Colors.black : theme.textPrimary),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Episodes List
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  else if (currentEpisodes.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No episodes found', style: TextStyle(color: theme.textSecondary))))
                  else
                    ...currentEpisodes.map((episode) {
                      final epNum = episode['episode_num'] ?? '';
                      return Card(
                        color: theme.cardBackground,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              episode['info']?['movie_image'] ?? _metadata?.posterUrl ?? widget.series.cover ?? '',
                              width: 100,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(Icons.movie, size: 40, color: theme.textSecondary.withOpacity(0.2)),
                            ),
                          ),
                          title: Text(
                            'E$epNum - ${episode['title'] ?? "Episode $epNum"}',
                            style: TextStyle(color: theme.cardTextPrimary, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            episode['info']?['plot'] ?? 'No plot available',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.cardTextSecondary, fontSize: 13),
                          ),
                          trailing: Icon(Icons.play_circle_fill, color: theme.accentPrimary, size: 36),
                          onTap: () => _playEpisode(episode),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
