import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';

class XtreamService {
  final String baseUrl;
  final String username;
  final String password;

  // Cache for categories
  Map<String, String> _liveCategories = {};
  Map<String, String> _vodCategories = {};
  Map<String, String> _seriesCategories = {};

  XtreamService({
    required String baseUrl,
    required this.username,
    required this.password,
  }) : baseUrl = _normalizeUrl(baseUrl);

  static String _normalizeUrl(String url) {
    var normalized = url.trim();
    // Remove trailing slashes
    normalized = normalized.replaceAll(RegExp(r'/+$'), '');
    // Remove /player_api.php if present
    normalized = normalized.replaceAll(RegExp(r'/player_api\.php$'), '');
    return normalized;
  }

  /// Load live categories
  Future<void> _loadLiveCategories() async {
    try {
      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_live_categories',
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri, 
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _liveCategories.clear();
        for (var cat in data) {
          final id = cat['category_id']?.toString() ?? '';
          final name = cat['category_name']?.toString() ?? 'Unknown';
          if (id.isNotEmpty) {
            _liveCategories[id] = name;
          }
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  /// Load VOD categories
  Future<void> _loadVodCategories() async {
    try {
      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_vod_categories',
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _vodCategories.clear();
        for (var cat in data) {
          final id = cat['category_id']?.toString() ?? '';
          final name = cat['category_name']?.toString() ?? 'Unknown';
          if (id.isNotEmpty) {
            _vodCategories[id] = name;
          }
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  /// Load series categories
  Future<void> _loadSeriesCategories() async {
    try {
      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_series_categories',
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _seriesCategories.clear();
        for (var cat in data) {
          final id = cat['category_id']?.toString() ?? '';
          final name = cat['category_name']?.toString() ?? 'Unknown';
          if (id.isNotEmpty) {
            _seriesCategories[id] = name;
          }
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  /// Get live TV channels and categories
  Future<Map<String, dynamic>> getLiveChannels() async {
    try {
      // Load categories first
      await _loadLiveCategories();

      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_live_streams',
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        // Parse channels
        final channels = <Channel>[];
        final categorySet = <String>{};

        for (var item in data) {
          final channel = Channel();
          channel.name = item['name'] ?? 'Unknown';
          channel.url = '$baseUrl/live/$username/$password/${item['stream_id']}.ts';

          // Get category name from the map using category_id
          final categoryId = item['category_id']?.toString() ?? '';
          channel.group = _liveCategories[categoryId] ?? item['category_name'] ?? 'Uncategorized';

          channel.logo = item['stream_icon'];
          channel.tvgId = int.tryParse(item['stream_id']?.toString() ?? '0');
          channel.contentType = ContentType.live;
          channels.add(channel);

          // Track categories
          if (channel.group != null && channel.group!.isNotEmpty) {
            categorySet.add(channel.group!);
          }
        }

        return {
          'success': true,
          'channels': channels,
          'message': 'Loaded ${channels.length} live channels',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch live channels: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching live channels: $e',
      };
    }
  }

  /// Get VOD (Movies)
  Future<Map<String, dynamic>> getMovies() async {
    try {
      // Load categories first
      await _loadVodCategories();

      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_vod_streams',
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        final movies = <VodItem>[];

        for (var item in data) {
          final movie = VodItem.fromJson(item, baseUrl, username, password, categoryMap: _vodCategories);
          movies.add(movie);
        }

        return {
          'success': true,
          'movies': movies,
          'message': 'Loaded ${movies.length} movies',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch movies: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching movies: $e',
      };
    }
  }

  /// Get Series
  Future<Map<String, dynamic>> getSeries() async {
    try {
      // Load categories first
      await _loadSeriesCategories();

      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_series',
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        final seriesList = <SeriesItem>[];

        for (var item in data) {
          final series = SeriesItem.fromJson(item, categoryMap: _seriesCategories);
          seriesList.add(series);
        }

        return {
          'success': true,
          'series': seriesList,
          'message': 'Loaded ${seriesList.length} series',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch series: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching series: $e',
      };
    }
  }

  /// Get VOD (Movie) information
  Future<Map<String, dynamic>> getVodInfo(int vodId) async {
    try {
      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_vod_info',
        'vod_id': vodId.toString(),
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'data': data,
          'message': 'Loaded movie info',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch movie info: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching movie info: $e',
      };
    }
  }

  /// Get series information and episodes
  Future<Map<String, dynamic>> getSeriesInfo(int seriesId) async {
    try {
      final queryParams = {
        'username': username,
        'password': password,
        'action': 'get_series_info',
        'series_id': seriesId.toString(),
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'data': data,
          'message': 'Loaded series info',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch series info: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching series info: $e',
      };
    }
  }

  /// Verify credentials by testing basic API call
  Future<bool> verifyCredentials() async {
    try {
      final queryParams = {
        'username': username,
        'password': password,
      };
      
      final baseUri = Uri.parse(baseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.isEmpty || baseUri.path == "/" ? "" : baseUri.path}/player_api.php',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'IPTVSmartersPlayer'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('user_info')) {
          final auth = data['user_info']['auth'];
          return auth == 1 || auth == "1";
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Helper: Parse rating from various formats
  double? _parseRating(dynamic rating) {
    if (rating == null) return null;

    if (rating is num) {
      return rating.toDouble();
    }

    if (rating is String) {
      return double.tryParse(rating);
    }

    return null;
  }
}
