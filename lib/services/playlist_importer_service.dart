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
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF1B1B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
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
                        isEdit ? 'Updating Playlist...' : 'Adding Playlist...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Importing channels and metadata for ${playlist.name}',
                        style: const TextStyle(color: Color(0xFF9E9EA8), fontSize: 12),
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
      ),
    );

    try {
      // Auto-detect and convert Xtream get.php M3U URLs to full Xtream Codes API
      if (playlist.sourceType == PlaylistSourceType.m3u &&
          playlist.url.contains('get.php') &&
          playlist.url.contains('username=') &&
          playlist.url.contains('password=')) {
        try {
          final uri = Uri.parse(playlist.url);
          final user = uri.queryParameters['username'];
          final pass = uri.queryParameters['password'];
          if (user != null && pass != null) {
            playlist.sourceType = PlaylistSourceType.xtreamCodes;
            playlist.url = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
            playlist.username = user;
            playlist.password = pass;
          }
        } catch (_) {}
      }

      List<Channel> channels = [];

      if (playlist.isStalker) {
        final service = StalkerService(
          portalUrl: playlist.url,
          macAddress: playlist.macAddress ?? '00:1A:79:00:00:00',
          serialNumber: playlist.serialNumber ?? 'MAG254_SERIAL_DEFAULT',
          deviceId: playlist.deviceId ?? 'MAG254_DEVICE_ID_DEFAULT',
          deviceId2: playlist.deviceId2 ?? 'MAG254_DEVICE_ID2_DEFAULT',
          signature: playlist.signature ?? 'MAG254_SIGNATURE_DEFAULT',
        );

        final liveResult = await service.getLiveChannels();
        if (liveResult['success'] == true) {
          channels.addAll(liveResult['channels'] as List<Channel>);
        }

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
        }

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
        }
      } else if (playlist.isXtreamCodes) {
        final service = XtreamService(
          baseUrl: playlist.url,
          username: playlist.username!,
          password: playlist.password!,
        );

        final liveResult = await service.getLiveChannels();
        if (liveResult['success'] == true) {
          channels.addAll(liveResult['channels'] as List<Channel>);
        }

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
        }

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
        }
      } else {
        channels = await M3UParser.parseFromUrl(playlist.getFullUrl());
      }

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
