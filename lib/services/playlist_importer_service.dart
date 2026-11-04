import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import 'database_service.dart';
import 'epg_service.dart';
import 'm3u_parser.dart';
import 'preferences_service.dart';
import 'stalker_service.dart';
import 'vortextube_service.dart';
import 'xtream_service.dart';

class PlaylistImporterService {
  /// Imports or updates a playlist and its channels, saving to DatabaseService.
  static Future<Map<String, dynamic>> importPlaylist(
    BuildContext context,
    Playlist playlist, {
    bool isEdit = false,
  }) async {
    final ValueNotifier<String> statusNotifier = ValueNotifier<String>('Initializing connection...');
    final ValueNotifier<String> subStatusNotifier = ValueNotifier<String>('Connecting to portal server...');

    // Show a detailed live progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF14141B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF282834)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 22.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFFF0033),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Updating "${playlist.name}"...' : 'Importing "${playlist.name}"...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ValueListenableBuilder<String>(
                        valueListenable: statusNotifier,
                        builder: (context, status, _) => Text(
                          status,
                          style: const TextStyle(color: Color(0xFFE5E5E5), fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ValueListenableBuilder<String>(
                        valueListenable: subStatusNotifier,
                        builder: (context, subStatus, _) => Text(
                          subStatus,
                          style: const TextStyle(color: Color(0xFF8D8D9B), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      String? originalM3uUrl;
      // Auto-detect and convert Xtream get.php or player_api.php or enigma2.php M3U URLs
      if (playlist.sourceType == PlaylistSourceType.m3u &&
          (playlist.url.contains('get.php') || playlist.url.contains('player_api.php') || playlist.url.contains('enigma2.php')) &&
          playlist.url.contains('username=') &&
          playlist.url.contains('password=')) {
        originalM3uUrl = playlist.url;
        try {
          final uri = Uri.parse(playlist.url);
          final user = uri.queryParameters['username'];
          final pass = uri.queryParameters['password'];
          if (user != null && pass != null) {
            final isEnigma = playlist.url.contains('enigma2.php');
            if (!isEnigma) {
              playlist.sourceType = PlaylistSourceType.xtreamCodes;
            }
            final pathSegments = List<String>.from(uri.pathSegments);
            if (pathSegments.isNotEmpty && (pathSegments.last == 'get.php' || pathSegments.last == 'player_api.php')) {
              pathSegments.removeLast();
            }
            final basePath = pathSegments.isEmpty ? '' : '/${pathSegments.join('/')}';
            playlist.url = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}$basePath';
            playlist.username = user;
            playlist.password = pass;
          }
        } catch (_) {}
      }

      List<Channel> channels = [];

      if (playlist.isStalker) {
        statusNotifier.value = 'Connecting to Stalker MAC Portal...';
        subStatusNotifier.value = 'Handshaking with portal server...';

        final service = StalkerService(
          portalUrl: playlist.url,
          macAddress: playlist.macAddress ?? '00:1A:79:00:00:00',
          serialNumber: playlist.serialNumber ?? 'MAG254_SERIAL_DEFAULT',
          deviceId: playlist.deviceId ?? 'MAG254_DEVICE_ID_DEFAULT',
          deviceId2: playlist.deviceId2 ?? 'MAG254_DEVICE_ID2_DEFAULT',
          signature: playlist.signature ?? 'MAG254_SIGNATURE_DEFAULT',
        );

        statusNotifier.value = 'Fetching Live TV Channels...';
        final liveResult = await service.getLiveChannels();
        if (liveResult['success'] == true) {
          final liveCh = liveResult['channels'] as List<Channel>;
          channels.addAll(liveCh);
          subStatusNotifier.value = 'Loaded ${liveCh.length} live channels';
        }

        statusNotifier.value = 'Fetching Movies / VOD Catalog...';
        final moviesResult = await service.getMovies();
        if (moviesResult['success'] == true) {
          final movies = moviesResult['movies'] as List;
          for (var movie in movies) {
            final channel = Channel()
              ..name = movie.name
              ..url = movie.streamUrl
              ..logo = movie.streamIcon ?? movie.posterUrl
              ..group = movie.categoryName
              ..description = movie.plot
              ..tvgId = movie.streamId
              ..userAgent = StalkerService.userAgent
              ..referer = '${StalkerService.normalizeUrl(playlist.url)}/c/'
              ..contentType = ContentType.movie;
            channels.add(channel);
          }
          subStatusNotifier.value = 'Loaded ${movies.length} movies';
        }

        statusNotifier.value = 'Fetching TV Series Catalog...';
        final seriesResult = await service.getSeries();
        if (seriesResult['success'] == true) {
          final seriesList = seriesResult['series'] as List;
          for (var series in seriesList) {
            final channel = Channel()
              ..name = series.name
              ..url = 'stalker://series/${series.id}'
              ..logo = series.cover ?? series.posterUrl
              ..group = series.categoryName
              ..description = series.plot
              ..userAgent = StalkerService.userAgent
              ..referer = '${StalkerService.normalizeUrl(playlist.url)}/c/'
              ..tvgId = int.tryParse(series.id)
              ..contentType = ContentType.series;
            channels.add(channel);
          }
          subStatusNotifier.value = 'Loaded ${seriesList.length} series';
        }
      } else if (playlist.isXtreamCodes) {
        statusNotifier.value = 'Connecting to Xtream Codes API...';
        subStatusNotifier.value = 'Authenticating with server ${playlist.url}...';

        final service = XtreamService(
          baseUrl: playlist.url,
          username: playlist.username!,
          password: playlist.password!,
        );

        // Fetch Live Channels
        statusNotifier.value = 'Fetching Live TV Channels & Streams...';
        final liveResult = await service.getLiveChannels();
        if (liveResult['success'] == true) {
          final liveList = liveResult['channels'] as List<Channel>;
          channels.addAll(liveList);
          subStatusNotifier.value = 'Loaded ${liveList.length} live channels';
        }

        // Fetch VOD (Movies)
        statusNotifier.value = 'Fetching Movies / VOD Catalog...';
        final moviesResult = await service.getMovies();
        if (moviesResult['success'] == true) {
          final movies = moviesResult['movies'] as List;
          for (var movie in movies) {
            final channel = Channel()
              ..name = movie.name
              ..url = movie.streamUrl
              ..logo = movie.posterUrl
              ..group = movie.categoryName
              ..description = movie.plot
              ..tvgId = movie.streamId
              ..contentType = ContentType.movie;
            channels.add(channel);
          }
          subStatusNotifier.value = 'Loaded ${movies.length} movies';
        }

        // Fetch Series
        statusNotifier.value = 'Fetching TV Series & Box Sets...';
        final seriesResult = await service.getSeries();
        if (seriesResult['success'] == true) {
          final seriesList = seriesResult['series'] as List;
          for (var series in seriesList) {
            final channel = Channel()
              ..name = series.name
              ..url = 'xtream://series/${series.id}'
              ..logo = series.posterUrl
              ..group = series.categoryName
              ..description = series.plot
              ..tvgId = int.tryParse(series.id)
              ..contentType = ContentType.series;
            channels.add(channel);
          }
          subStatusNotifier.value = 'Loaded ${seriesList.length} series';
        }

        // Fallback: If player_api.php returned zero content, try fetching via m3u_plus URL
        if (channels.isEmpty) {
          statusNotifier.value = 'Falling back to M3U_Plus Stream Ingestion...';
          subStatusNotifier.value = 'Downloading playlist streams with STB headers...';
          final m3uFallbackUrl = originalM3uUrl ??
              '${playlist.url}/get.php?username=${playlist.username}&password=${playlist.password}&type=m3u_plus&output=ts';
          try {
            final fallbackChannels = await M3UParser.parseFromUrl(m3uFallbackUrl);
            if (fallbackChannels.isNotEmpty) {
              channels.addAll(fallbackChannels);
            }
          } catch (_) {}
        }
      } else if (playlist.url.contains('enigma2.php')) {
        statusNotifier.value = 'Connecting to Enigma2 OpenWebif...';
        subStatusNotifier.value = 'Parsing XML stream channels...';
        final enigmaChannels = await XtreamService.parseEnigma2(
          enigma2Url: playlist.url,
          username: playlist.username ?? '',
          password: playlist.password ?? '',
        );
        channels.addAll(enigmaChannels);
      } else {
        statusNotifier.value = 'Downloading M3U Playlist...';
        subStatusNotifier.value = 'Parsing stream entries and logos...';
        channels = await M3UParser.parseFromUrl(playlist.getFullUrl());
      }

      // STRICT VALIDATION: MUST FETCH CONTENTS BEFORE ADDING PORTAL
      if (channels.isEmpty) {
        throw Exception('Failed to fetch any channels or streams from this portal. Please check credentials, server URL, or playlist accessibility.');
      }

      statusNotifier.value = 'Saving to Database...';
      subStatusNotifier.value = 'Persisting ${channels.length} channels...';

      playlist.channelCount = channels.length;
      playlist.lastUpdated = DateTime.now();
      await DatabaseService.addPlaylist(playlist);

      for (var channel in channels) {
        channel.playlistId = playlist.id;
      }
      await DatabaseService.addChannels(channels);

      if (!isEdit) {
        await PreferencesService.setActivePlaylistId(playlist.id);
      }

      if (!playlist.isXtreamCodes && !playlist.isStalker) {
        try {
          await EpgService.loadEpgFromPlaylistUrl(playlist.getFullUrl());
        } catch (_) {}
      }

      VortexTubeService.invalidateCache();

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      return {
        'success': true,
        'count': channels.length,
      };
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
