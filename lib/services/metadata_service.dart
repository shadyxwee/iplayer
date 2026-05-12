import '../models/media_metadata.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';
import 'xtream_service.dart';
import 'tmdb_service.dart';

class _CachedEntry {
  final MediaMetadata metadata;
  final DateTime timestamp;
  _CachedEntry(this.metadata) : timestamp = DateTime.now();
  bool get isExpired => DateTime.now().difference(timestamp).inHours >= 1;
}

class MetadataService {
  final XtreamService? xtreamService;
  
  // Hardened Cache: TTL + Max Size
  static final Map<String, _CachedEntry> _cache = {};
  static const int _maxCacheSize = 250;

  MetadataService({this.xtreamService});

  static MediaMetadata? _getFromCache(String key) {
    if (!_cache.containsKey(key)) return null;
    final entry = _cache[key]!;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.metadata;
  }

  static void _saveToCache(String key, MediaMetadata metadata) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry or just clear (simplified LRU)
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = _CachedEntry(metadata);
  }

  Future<T> _withRetry<T>(Future<T> Function() action, {int attempts = 2}) async {
    int count = 0;
    while (true) {
      try {
        return await action().timeout(const Duration(seconds: 8));
      } catch (e) {
        count++;
        if (count >= attempts) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * count));
      }
    }
  }

  /// Get metadata for a movie (VOD)
  Future<MediaMetadata> getMovieMetadata(VodItem movie) async {
    final cacheKey = 'movie_${movie.streamId}';
    final cached = _getFromCache(cacheKey);
    if (cached != null) return cached;

    MediaMetadata metadata = MediaMetadata(
      title: movie.name,
      rating: movie.rating > 0 ? movie.rating : null,
      posterUrl: movie.streamIcon,
      plot: movie.plot,
    );

    // 1. Primary: Xtream Info (if available)
    if (xtreamService != null) {
      try {
        final infoResult = await _withRetry(() => xtreamService!.getVodInfo(movie.streamId));
        if (infoResult['success'] == true && infoResult['data'] != null) {
          final xtreamMeta = MediaMetadata.fromXtreamVodInfo(infoResult['data']);
          metadata = MediaMetadata.merge(xtreamMeta, metadata);
        }
      } catch (_) {}
    }

    // 2. Fallback: TMDB/OMDb
    // Only fetch if missing important info (plot is minimal or rating missing)
    bool plotEmpty = metadata.plot == null || metadata.plot!.length < 10;
    if (plotEmpty || metadata.rating == null || metadata.rating == 0) {
      final fallbackMeta = await TmdbService.getFallbackMetadata(movie.name, isMovie: true, tmdbId: metadata.tmdbId);
      if (fallbackMeta != null) {
        metadata = MediaMetadata.merge(metadata, fallbackMeta);
      }
    }

    _saveToCache(cacheKey, metadata);
    return metadata;
  }

  /// Get metadata for a series
  Future<MediaMetadata> getSeriesMetadata(SeriesItem series) async {
    final cacheKey = 'series_${series.seriesId}';
    final cached = _getFromCache(cacheKey);
    if (cached != null) return cached;

    MediaMetadata metadata = MediaMetadata(
      title: series.name,
      rating: series.rating > 0 ? series.rating : null,
      posterUrl: series.cover,
      plot: series.plot,
    );

    // 1. Primary: Xtream Info (if available)
    if (xtreamService != null) {
      try {
        final infoResult = await _withRetry(() => xtreamService!.getSeriesInfo(series.seriesId));
        if (infoResult['success'] == true && infoResult['data'] != null) {
          final xtreamMeta = MediaMetadata.fromXtreamSeriesInfo(infoResult['data']);
          metadata = MediaMetadata.merge(xtreamMeta, metadata);
        }
      } catch (_) {}
    }

    // 2. Fallback: TMDB/OMDb
    bool plotEmpty = metadata.plot == null || metadata.plot!.length < 10;
    if (plotEmpty || metadata.rating == null || metadata.rating == 0) {
      final fallbackMeta = await TmdbService.getFallbackMetadata(series.name, isMovie: false, tmdbId: metadata.tmdbId);
      if (fallbackMeta != null) {
        metadata = MediaMetadata.merge(metadata, fallbackMeta);
      }
    }

    _saveToCache(cacheKey, metadata);
    return metadata;
  }

  /// Resolve metadata for a channel (M3U compatibility)
  static Future<MediaMetadata> resolveChannelMetadata(String name, bool isMovie) async {
    final cacheKey = 'm3u_${isMovie ? "m" : "s"}_$name';
    final cached = _getFromCache(cacheKey);
    if (cached != null) return cached;

    final fallbackMeta = await TmdbService.getFallbackMetadata(name, isMovie: isMovie);
    final result = fallbackMeta ?? MediaMetadata(title: name);
    
    _saveToCache(cacheKey, result);
    return result;
  }
}
