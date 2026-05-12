import '../models/channel.dart';
import '../models/series.dart';

class SeriesParser {
  static Map<String, Series> groupIntoSeries(List<Channel> channels) {
    final seriesMap = <String, Series>{};
    for (final channel in channels) {
      if (channel.contentType == ContentType.series) {
        String? seriesId;
        String seriesName;
        
        // Try to get series ID from Xtream URL
        if (channel.url.startsWith('xtream://series/')) {
          final parts = channel.url.replaceFirst('xtream://series/', '').split('/');
          if (parts.isNotEmpty) {
            seriesId = parts[0];
          }
        }
        
        seriesName = _getSeriesName(channel.name);
        
        // Use seriesId as key if available to be more precise, otherwise use name
        final key = seriesId ?? seriesName;
        
        if (!seriesMap.containsKey(key)) {
          seriesMap[key] = Series(
            id: seriesId,
            playlistId: channel.playlistId,
            name: seriesName,
            group: channel.group ?? "Uncategorized",
            logo: channel.logo,
            poster: channel.logo,
            rating: channel.rating,
            seasons: [],
          );
        }
        
        final series = seriesMap[key]!;
        
        // Try to parse season and episode
        final epInfo = _parseEpisodeInfo(channel.name);
        int seasonNum = epInfo['season'] ?? 1;
        int episodeNum = epInfo['episode'] ?? 1;
        
        // Find or create season
        Season? season;
        for (var s in series.seasons) {
          if (s.seasonNumber == seasonNum) {
            season = s;
            break;
          }
        }
        
        if (season == null) {
          season = Season(seasonNumber: seasonNum, episodes: []);
          series.seasons.add(season);
        }

        // Add episode
        season.episodes.add(Episode(
          name: channel.name,
          url: channel.url,
          episodeNumber: episodeNum,
        ));
      }
    }
    return seriesMap;
  }

  static Map<String, int?> _parseEpisodeInfo(String name) {
    // S01E01
    var match = RegExp(r's(\d+)e(\d+)', caseSensitive: false).firstMatch(name);
    if (match != null) {
      return {
        'season': int.tryParse(match.group(1)!),
        'episode': int.tryParse(match.group(2)!),
      };
    }
    
    // 1x01
    match = RegExp(r'(\d+)x(\d+)', caseSensitive: false).firstMatch(name);
    if (match != null) {
      return {
        'season': int.tryParse(match.group(1)!),
        'episode': int.tryParse(match.group(2)!),
      };
    }

    return {'season': null, 'episode': null};
  }

  static String _getSeriesName(String fullName) {
    String name = fullName;
    // Remove S01E01
    name = name.replaceAll(RegExp(r's\d+e\d+', caseSensitive: false), ' ');
    // Remove 1x01
    name = name.replaceAll(RegExp(r'\d+x\d+', caseSensitive: false), ' ');
    // Remove trailing episode info like "E01" at the end if not caught above
    name = name.replaceAll(RegExp(r'\s+e\d+$', caseSensitive: false), ' ');
    
    // Clean up
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove trailing dashes or dots
    if (name.endsWith('-') || name.endsWith('.')) {
      name = name.substring(0, name.length - 1).trim();
    }
    
    return name;
  }
}
