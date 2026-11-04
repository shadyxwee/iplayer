import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/series.dart';
import '../../models/series_item.dart';
import '../../models/media_metadata.dart';
import '../../models/channel.dart';
import '../../models/playlist.dart';
import '../../services/metadata_service.dart';
import '../../services/database_service.dart';
import '../../services/stalker_service.dart';
import '../../services/xtream_service.dart';
import '../player/video_player_screen.dart';
import '../player/mobile_video_player_screen.dart';
import 'dart:io' show Platform;

class SeriesDetailScreen extends StatefulWidget {
  final Series series;
  const SeriesDetailScreen({Key? key, required this.series}) : super(key: key);

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

enum _SeriesFocusSection {
  infoAction,
  seasons,
  episodes,
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  MediaMetadata? _metadata;
  Map<String, dynamic>? _seriesData;
  bool _isLoading = true;
  String? _selectedSeason;

  // Spatial Navigation State
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _seasonsScrollController = ScrollController();

  _SeriesFocusSection _currentSection = _SeriesFocusSection.infoAction;
  int _focusedSeasonIndex = 0;
  int _focusedEpisodeIndex = 0;
  final Map<int, GlobalKey> _episodeKeys = {};

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _mainScrollController.dispose();
    _seasonsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoading = true);
    
    XtreamService? xtreamService;
    final playlistId = widget.series.playlistId;
    Playlist? currentPlaylist;
    if (playlistId != null) {
      currentPlaylist = await DatabaseService.getPlaylistById(playlistId);
      if (currentPlaylist != null && currentPlaylist.isXtreamCodes) {
        xtreamService = XtreamService(
          baseUrl: currentPlaylist.url,
          username: currentPlaylist.username!,
          password: currentPlaylist.password!,
        );
      }
    }

    final metadataService = MetadataService(xtreamService: xtreamService);
    
    MediaMetadata meta;
    if (currentPlaylist != null && currentPlaylist.isStalker) {
       final seriesId = widget.series.id ?? '0';
       final stalkerService = StalkerService(
         portalUrl: currentPlaylist.url,
         macAddress: currentPlaylist.macAddress ?? '00:1A:79:00:00:00',
         serialNumber: currentPlaylist.serialNumber ?? 'MAG254_SERIAL_DEFAULT',
         deviceId: currentPlaylist.deviceId ?? 'MAG254_DEVICE_ID_DEFAULT',
         deviceId2: currentPlaylist.deviceId2 ?? 'MAG254_DEVICE_ID2_DEFAULT',
         signature: currentPlaylist.signature ?? 'MAG254_SIGNATURE_DEFAULT',
       );
       meta = await MetadataService.resolveChannelMetadata(widget.series.name, false);
       try {
         final info = await stalkerService.getSeriesInfo(seriesId);
         if (info['success'] == true && info['data'] != null) {
           _seriesData = info['data'];
           _selectedSeason = '1';
         }
       } catch (e) {
         print('Error loading Stalker series info: $e');
       }
    } else if (xtreamService != null) {
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

  void _handleSeriesKeyEvent(KeyEvent event, List seasons, List currentEpisodes) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return;
    }

    const int cols = 5; // 5 episode cards per row

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_currentSection == _SeriesFocusSection.infoAction) {
          if (seasons.isNotEmpty) {
            _currentSection = _SeriesFocusSection.seasons;
            _focusedSeasonIndex = 0;
            _ensureVisibleSeason(0);
          } else if (currentEpisodes.isNotEmpty) {
            _currentSection = _SeriesFocusSection.episodes;
            _focusedEpisodeIndex = 0;
            _ensureVisibleEpisode(0);
          }
        } else if (_currentSection == _SeriesFocusSection.seasons) {
          if (currentEpisodes.isNotEmpty) {
            _currentSection = _SeriesFocusSection.episodes;
            _focusedEpisodeIndex = 0;
            _ensureVisibleEpisode(0);
          }
        } else if (_currentSection == _SeriesFocusSection.episodes) {
          if (_focusedEpisodeIndex + cols < currentEpisodes.length) {
            _focusedEpisodeIndex += cols;
            _ensureVisibleEpisode(_focusedEpisodeIndex);
          }
        }
      });
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_currentSection == _SeriesFocusSection.episodes) {
          if (_focusedEpisodeIndex >= cols) {
            _focusedEpisodeIndex -= cols;
            _ensureVisibleEpisode(_focusedEpisodeIndex);
          } else {
            // First row of episodes -> move up to seasons
            if (seasons.isNotEmpty) {
              _currentSection = _SeriesFocusSection.seasons;
              _ensureVisibleSeason(_focusedSeasonIndex);
            } else {
              _currentSection = _SeriesFocusSection.infoAction;
            }
          }
        } else if (_currentSection == _SeriesFocusSection.seasons) {
          _currentSection = _SeriesFocusSection.infoAction;
        }
      });
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        if (_currentSection == _SeriesFocusSection.seasons) {
          if (_focusedSeasonIndex > 0) {
            _focusedSeasonIndex--;
            _selectSeasonByIndex(_focusedSeasonIndex, seasons);
            _ensureVisibleSeason(_focusedSeasonIndex);
          }
        } else if (_currentSection == _SeriesFocusSection.episodes) {
          if (_focusedEpisodeIndex % cols > 0) {
            _focusedEpisodeIndex--;
            _ensureVisibleEpisode(_focusedEpisodeIndex);
          }
        }
      });
    } else if (key == LogicalKeyboardKey.arrowRight) {
      setState(() {
        if (_currentSection == _SeriesFocusSection.seasons) {
          if (_focusedSeasonIndex < seasons.length - 1) {
            _focusedSeasonIndex++;
            _selectSeasonByIndex(_focusedSeasonIndex, seasons);
            _ensureVisibleSeason(_focusedSeasonIndex);
          }
        } else if (_currentSection == _SeriesFocusSection.episodes) {
          if (_focusedEpisodeIndex % cols < cols - 1 && _focusedEpisodeIndex < currentEpisodes.length - 1) {
            _focusedEpisodeIndex++;
            _ensureVisibleEpisode(_focusedEpisodeIndex);
          }
        }
      });
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space) {
      if (_currentSection == _SeriesFocusSection.infoAction) {
        if (currentEpisodes.isNotEmpty) {
          _playEpisode(currentEpisodes.first);
        }
      } else if (_currentSection == _SeriesFocusSection.seasons) {
        _selectSeasonByIndex(_focusedSeasonIndex, seasons);
      } else if (_currentSection == _SeriesFocusSection.episodes) {
        if (_focusedEpisodeIndex < currentEpisodes.length) {
          _playEpisode(currentEpisodes[_focusedEpisodeIndex]);
        }
      }
    }
  }

  void _selectSeasonByIndex(int index, List seasons) {
    if (index >= 0 && index < seasons.length) {
      final sNum = (seasons[index]['season_number'] ?? index + 1).toString();
      setState(() {
        _selectedSeason = sNum;
        _focusedEpisodeIndex = 0;
      });
    }
  }

  void _ensureVisibleSeason(int index) {
    if (!_seasonsScrollController.hasClients) return;
    const double chipWidth = 110.0;
    final target = (index * chipWidth) - 100.0;
    _seasonsScrollController.animateTo(
      target.clamp(0.0, _seasonsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _ensureVisibleEpisode(int index) {
    final key = _episodeKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          final seasonKey = _selectedSeason!;
          final episodesForSeason = episodesRaw[seasonKey] ?? episodesRaw[int.tryParse(seasonKey)];
          if (episodesForSeason is List) {
            currentEpisodes = episodesForSeason;
          }
        } else if (episodesRaw is List) {
          currentEpisodes = episodesRaw.where((ep) {
            final sNum = (ep['season'] ?? ep['season_number'] ?? '1').toString();
            return sNum == _selectedSeason;
          }).toList();
        }
      } else if (widget.series.seasons.isNotEmpty) {
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

    return KeyboardListener(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleSeriesKeyEvent(event, seasons, currentEpisodes),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          child: ListView(
            controller: _mainScrollController,
            padding: const EdgeInsets.fromLTRB(36, 24, 36, 40),
            children: [
              // Top Bar with Back Button & Breadcrumb
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF282828)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Back to Series', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 1. Top Section – Series Info Card
              _buildSeriesInfoCard(currentEpisodes),

              const SizedBox(height: 32),

              // 2. Seasons Section (Horizontal Row)
              if (seasons.isNotEmpty) ...[
                const Text(
                  'SEASONS',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    controller: _seasonsScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: seasons.length,
                    itemBuilder: (context, index) {
                      final seasonNum = (seasons[index]['season_number'] ?? index + 1).toString();
                      final isSelected = _selectedSeason == seasonNum;
                      final isFocused = _currentSection == _SeriesFocusSection.seasons && _focusedSeasonIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSeason = seasonNum;
                            _currentSection = _SeriesFocusSection.seasons;
                            _focusedSeasonIndex = index;
                            _focusedEpisodeIndex = 0;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEEEEEE)
                                : (isFocused ? const Color(0xFF2E2E32) : const Color(0xFF1C1C1F)),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isFocused ? Colors.white : Colors.transparent,
                              width: isFocused ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Season $seasonNum',
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected || isFocused ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // 3. Episodes Section (2:3 Grid matching Movies page cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EPISODES (${currentEpisodes.length})',
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                _buildEpisodesSkeleton()
              else if (currentEpisodes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No episodes found for this season.', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 22,
                    childAspectRatio: 0.68, // Match standard 2:3 vertical poster card
                  ),
                  itemCount: currentEpisodes.length,
                  itemBuilder: (context, epIdx) {
                    final ep = currentEpisodes[epIdx];
                    final isFocused = _currentSection == _SeriesFocusSection.episodes && _focusedEpisodeIndex == epIdx;
                    final key = _episodeKeys.putIfAbsent(epIdx, () => GlobalKey());

                    final epNum = ep['episode_num'] ?? '${epIdx + 1}';
                    final title = ep['title'] ?? 'Episode $epNum';
                    final thumbUrl = ep['info']?['movie_image'] ?? _metadata?.posterUrl ?? widget.series.cover;

                    return GestureDetector(
                      key: key,
                      onTap: () {
                        setState(() {
                          _currentSection = _SeriesFocusSection.episodes;
                          _focusedEpisodeIndex = epIdx;
                        });
                        _playEpisode(ep);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFocused ? Colors.white : const Color(0xFF282828),
                            width: isFocused ? 2.5 : 1,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 18,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Container(
                                  color: const Color(0xFF161616),
                                  child: Center(
                                    child: thumbUrl != null && thumbUrl.isNotEmpty
                                        ? Image.network(
                                            thumbUrl,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.movie_outlined, color: Colors.white24, size: 40),
                                          )
                                        : const Icon(Icons.movie_outlined, color: Colors.white24, size: 40),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'E$epNum • $title',
                                    style: TextStyle(
                                      color: isFocused ? Colors.white : const Color(0xFFE0E0E0),
                                      fontSize: 13,
                                      fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ep['info']?['plot'] ?? 'Episode $epNum',
                                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesInfoCard(List currentEpisodes) {
    final isInfoFocused = _currentSection == _SeriesFocusSection.infoAction;
    final posterUrl = _metadata?.posterUrl ?? widget.series.cover;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInfoFocused ? Colors.white : const Color(0xFF26262B),
          width: isInfoFocused ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 150,
              height: 225,
              color: const Color(0xFF202020),
              child: posterUrl != null && posterUrl.isNotEmpty
                  ? Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.movie, size: 50, color: Colors.white24),
                    )
                  : const Icon(Icons.movie, size: 50, color: Colors.white24),
            ),
          ),
          const SizedBox(width: 28),

          // Series Info Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.series.name,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if ((_metadata?.rating ?? widget.series.rating ?? 0.0) > 0) ...[
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        (_metadata?.rating ?? widget.series.rating ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28282E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _metadata?.genre ?? widget.series.group ?? 'Series',
                        style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _metadata?.plot ?? widget.series.plot ?? 'No description available for this series.',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Play / Resume Button (Focusable)
                InkWell(
                  onTap: () {
                    if (currentEpisodes.isNotEmpty) {
                      _playEpisode(currentEpisodes.first);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isInfoFocused ? Colors.white : const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isInfoFocused
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.4),
                                blurRadius: 14,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: isInfoFocused ? Colors.black : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Play First Episode',
                          style: TextStyle(
                            color: isInfoFocused ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 18,
        mainAxisSpacing: 22,
        childAspectRatio: 0.68,
      ),
      itemCount: 10,
      itemBuilder: (context, idx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161618),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222226)),
          ),
        );
      },
    );
  }
}
