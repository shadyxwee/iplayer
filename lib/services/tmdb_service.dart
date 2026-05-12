import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/media_metadata.dart';
import 'config_service.dart';

class TmdbService {
  // API configuration is loaded from ConfigService
  // which reads from config.json in the project root

  // IMDb uses IMDBpy library or scraping - we'll use OMDb as fallback

  // Cache for ratings to avoid excessive API calls
  static final Map<String, double?> _ratingCache = {};

  // Fallback ratings for popular content (when API key is not available)
  static const Map<String, double> _fallbackRatings = {
    'breaking bad': 9.5,
    'game of thrones': 9.2,
    'the office': 9.0,
    'stranger things': 8.7,
    'the crown': 8.6,
    'the mandalorian': 8.7,
    'house of dragon': 8.5,
    'better call saul': 9.3,
    'the witcher': 8.2,
    'dark': 8.8,
    'ozark': 8.5,
    'peaky blinders': 8.8,
    'the boys': 8.7,
    'wheel of time': 7.8,
    'foundation': 7.8,
    'lord of the rings': 9.2,
    'avatar': 7.8,
    'inception': 8.8,
    'interstellar': 8.6,
    'the dark knight': 9.0,
    'pulp fiction': 8.9,
    'fight club': 8.8,
    'forrest gump': 8.8,
    'the matrix': 8.7,
    'titanic': 7.8,
    'gladiator': 8.5,
    'the shawshank redemption': 9.3,
    'the godfather': 9.2,
    'schindler\'s list': 8.9,
  };

  /// Search for metadata and return MediaMetadata (Fallback)
  static Future<MediaMetadata?> getFallbackMetadata(String title, {bool isMovie = true, String? tmdbId}) async {
    final cleanedTitle = cleanContentName(title);
    
    // 1. Try TMDB by ID if provided
    if (tmdbId != null && ConfigService.isTmdbConfigured()) {
      final meta = await _getTMDBMetadataById(tmdbId, isMovie);
      if (meta != null) return meta;
    }

    // 2. Try OMDb by title
    final omdbMeta = await _getOMDbMetadata(cleanedTitle, !isMovie);
    if (omdbMeta != null) return omdbMeta;

    // 3. Try TMDB by title
    if (ConfigService.isTmdbConfigured()) {
      final tmdbMeta = await _getTMDBMetadataByTitle(cleanedTitle, isMovie);
      if (tmdbMeta != null) return tmdbMeta;
    }

    return null;
  }

  static bool _isTitleMatch(String original, String match) {
    if (original.isEmpty || match.isEmpty) return false;
    final o = original.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final m = match.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Very basic check: one must contain the other or be high similarity
    if (o.contains(m) || m.contains(o)) return true;
    
    // For more complex fuzzy matching, we could use a package, but let's keep it surgical.
    return false;
  }

  static Future<MediaMetadata?> _getOMDbMetadata(String title, bool isTV) async {
    try {
      final type = isTV ? 'series' : 'movie';
      final omdbBaseUrl = ConfigService.getOmdbBaseUrl();
      final apiKey = ConfigService.getOmdbApiKey();
      
      String urlString = '$omdbBaseUrl/?t=${Uri.encodeComponent(title)}&type=$type&r=json';
      if (apiKey.isNotEmpty) {
        urlString += '&apikey=$apiKey';
      }
      
      final searchUrl = Uri.parse(urlString);

      final response = await http.get(searchUrl).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Response'] == 'True') {
          final foundTitle = data['Title']?.toString() ?? '';
          if (!_isTitleMatch(title, foundTitle)) return null;

          return MediaMetadata(
            title: foundTitle,
            plot: (data['Plot'] != 'N/A' && data['Plot'] != null) ? data['Plot'].toString() : null,
            posterUrl: (data['Poster'] != 'N/A' && data['Poster'] != null) ? data['Poster'].toString() : null,
            rating: double.tryParse(data['imdbRating']?.toString() ?? '0.0'),
            releaseDate: data['Released'] != 'N/A' ? data['Released']?.toString() : null,
            genre: data['Genre'] != 'N/A' ? data['Genre']?.toString() : null,
            cast: data['Actors'] != 'N/A' ? data['Actors']?.toString() : null,
            director: data['Director'] != 'N/A' ? data['Director']?.toString() : null,
            tmdbId: data['imdbID']?.toString(),
          );
        }
      }
    } catch (e) {
      print('OMDb fallback error: $e');
    }
    return null;
  }

  static Future<MediaMetadata?> _getTMDBMetadataByTitle(String title, bool isMovie) async {
    try {
      final type = isMovie ? 'movie' : 'tv';
      final baseUrl = ConfigService.getTmdbBaseUrl();
      final apiKey = ConfigService.getTmdbApiKey();
      final url = '$baseUrl/search/$type?api_key=$apiKey&query=${Uri.encodeComponent(title)}&language=en-US';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          // Find the best match instead of just the first
          for (final first in results) {
            final foundTitle = (first['title'] ?? first['name'])?.toString() ?? '';
            if (!_isTitleMatch(title, foundTitle)) continue;

            return MediaMetadata(
              title: foundTitle,
              plot: first['overview']?.toString(),
              posterUrl: first['poster_path'] != null ? 'https://image.tmdb.org/t/p/w500${first['poster_path']}' : null,
              backdropUrl: first['backdrop_path'] != null ? 'https://image.tmdb.org/t/p/original${first['backdrop_path']}' : null,
              rating: (first['vote_average'] as num?)?.toDouble(),
              releaseDate: (first['release_date'] ?? first['first_air_date'])?.toString(),
              tmdbId: first['id']?.toString(),
            );
          }
        }
      }
    } catch (e) {
      print('TMDB title search error: $e');
    }
    return null;
  }

  static Future<MediaMetadata?> _getTMDBMetadataById(String id, bool isMovie) async {
    try {
      final type = isMovie ? 'movie' : 'tv';
      final baseUrl = ConfigService.getTmdbBaseUrl();
      final apiKey = ConfigService.getTmdbApiKey();
      final url = '$baseUrl/$type/$id?api_key=$apiKey&language=en-US';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MediaMetadata(
          title: data['title'] ?? data['name'],
          plot: data['overview'],
          posterUrl: data['poster_path'] != null ? 'https://image.tmdb.org/t/p/w500${data['poster_path']}' : null,
          backdropUrl: data['backdrop_path'] != null ? 'https://image.tmdb.org/t/p/original${data['backdrop_path']}' : null,
          rating: (data['vote_average'] as num?)?.toDouble(),
          releaseDate: data['release_date'] ?? data['first_air_date'],
          tmdbId: data['id']?.toString(),
        );
      }
    } catch (e) {
      print('TMDB ID lookup error: $e');
    }
    return null;
  }

  /// Get rating for any content (automatically detects if movie or series)
  static Future<double?> getRating(String contentName, bool isMovie) async {
    if (isMovie) {
      return getMovieRatingFromApi(contentName);
    } else {
      return getSeriesRatingFromApi(contentName);
    }
  }

  /// Clean the content name for better search results
  /// Removes common patterns like year, quality indicators, etc.
  static String cleanContentName(String name) {
    // Remove year patterns like (2023), [2023]
    name = name.replaceAll(RegExp(r'[\[\(]\d{4}[\]\)]'), '');

    // Remove quality indicators
    name = name.replaceAll(RegExp(r'\b(1080p|720p|480p|4K|HD|CAM|TS|WEB-DL|BluRay|DVDRip)\b', caseSensitive: false), '');

    // Remove common separators and extra spaces
    name = name.replaceAll(RegExp(r'[._-]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ');

    return name.trim();
  }

  static Future<double?> getMovieRatingFromApi(String movieName) async {
    final meta = await getFallbackMetadata(movieName, isMovie: true);
    return meta?.rating;
  }

  static Future<double?> getSeriesRatingFromApi(String seriesName) async {
    final meta = await getFallbackMetadata(seriesName, isMovie: false);
    return meta?.rating;
  }

  static Future<double?> getMovieRating(String movieName) async => getMovieRatingFromApi(movieName);
  static Future<double?> getSeriesRating(String seriesName) async => getSeriesRatingFromApi(seriesName);

  /// Get movie overview/description from TMDB
  static Future<String?> getMovieDescription(String movieName) async {
    final meta = await getFallbackMetadata(movieName, isMovie: true);
    return meta?.plot;
  }

  /// Get TV series overview/description from TMDB
  static Future<String?> getSeriesDescription(String seriesName) async {
    final meta = await getFallbackMetadata(seriesName, isMovie: false);
    return meta?.plot;
  }

  /// Clear the rating cache
  static void clearCache() {
    _ratingCache.clear();
  }
}
