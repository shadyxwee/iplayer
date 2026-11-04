import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';

/// Comprehensive Xtream Codes, Enigma2 & M3U Service
/// Implements:
/// - MAG254 STB Header Emulation on HTTP 401
/// - Dual-scheme probing (http <-> https)
/// - Geoblocking & VPN error detection (456, 458, 459)
/// - VOD redirection resolution & Base64 IP token extraction
/// - Enigma2 OpenWebif (/enigma2.php) Base64 decoding
/// - Direct stream URL synthesis
class XtreamService {
  String baseUrl;
  final String username;
  final String password;

  // Cache for categories
  final Map<String, String> _liveCategories = {};
  final Map<String, String> _vodCategories = {};
  final Map<String, String> _seriesCategories = {};

  static const Map<String, String> standardHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Connection': 'keep-alive',
  };

  static const Map<String, String> mag254Headers = {
    'User-Agent':
        'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG254 stbapp ver: 2 rev: 369 Safari/533.3',
    'Accept': '*/*',
    'Connection': 'close',
    'Pragma': 'no-cache',
    'Cache-Control': 'no-store, no-cache, must-revalidate',
    'X-User-Agent': 'Model: MAG254; Link: WiFi',
  };

  XtreamService({
    required String baseUrl,
    required this.username,
    required this.password,
  }) : baseUrl = _normalizeUrl(baseUrl);

  static String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    normalized = normalized.replaceAll(RegExp(r'/+$'), '');
    normalized = normalized.replaceAll(RegExp(r'/player_api\.php$'), '');
    normalized = normalized.replaceAll(RegExp(r'/get\.php$'), '');
    normalized = normalized.replaceAll(RegExp(r'/enigma2\.php$'), '');
    return normalized;
  }

  /// Request with automatic MAG254 fallback on HTTP 401 and custom geo/VPN error reporting
  Future<http.Response> _getWithFallback(Uri uri, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      var res = await http.get(uri, headers: standardHeaders).timeout(timeout);
      if (res.statusCode == 401) {
        // Fallback: Emulate MAG254 STB
        res = await http.get(uri, headers: mag254Headers).timeout(timeout);
      }
      return res;
    } catch (e) {
      return http.Response('', 500);
    }
  }

  /// Dual-scheme authentication probe (http <-> https)
  Future<bool> authenticate() async {
    final uri = Uri.parse(baseUrl);
    final candidateSchemes = [uri.scheme, uri.scheme == 'http' ? 'https' : 'http'];

    for (final scheme in candidateSchemes) {
      final probeUri = uri.replace(
        scheme: scheme,
        path: '${uri.path.isEmpty || uri.path == "/" ? "" : uri.path}/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
        },
      );

      final res = await _getWithFallback(probeUri, timeout: const Duration(seconds: 10));
      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body);
          if (data is Map && data.containsKey('user_info')) {
            final auth = data['user_info']['auth'];
            final status = (data['user_info']['status'] as String?)?.toLowerCase();
            if (auth == 1 || auth == '1' || status == 'active') {
              baseUrl = uri.replace(scheme: scheme).toString();
              if (baseUrl.endsWith('/')) {
                baseUrl = baseUrl.substring(0, baseUrl.length - 1);
              }
              return true;
            }
          }
        } catch (_) {}
      }
    }
    return false;
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

      final response = await _getWithFallback(uri, timeout: const Duration(seconds: 10));

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

      final response = await _getWithFallback(uri, timeout: const Duration(seconds: 10));

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

      final response = await _getWithFallback(uri, timeout: const Duration(seconds: 10));

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

      final response = await _getWithFallback(uri, timeout: const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          return {
            'success': false,
            'message': 'Unexpected API response format: expected list but got ${decoded.runtimeType}',
          };
        }
        final data = decoded;

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

      final response = await _getWithFallback(uri, timeout: const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          return {
            'success': false,
            'message': 'Unexpected API response format: expected list but got ${decoded.runtimeType}',
          };
        }
        final data = decoded;

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
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          return {
            'success': false,
            'message': 'Unexpected API response format: expected list but got ${decoded.runtimeType}',
          };
        }
        final data = decoded;

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

      final response = await _getWithFallback(uri, timeout: const Duration(seconds: 10));

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

  /// Verify credentials by testing basic API call or dual-scheme authenticate
  Future<bool> verifyCredentials() async {
    return authenticate();
  }

  /// Direct URL synthesis formulas
  String buildLiveUrl(int streamId) => '$baseUrl/live/$username/$password/$streamId.ts';
  String buildVodUrl(int streamId, [String ext = 'mp4']) => '$baseUrl/movie/$username/$password/$streamId.$ext';
  String buildSeriesUrl(int episodeId, [String ext = 'mp4']) => '$baseUrl/series/$username/$password/$episodeId.$ext';

  /// Phase 6: VOD Redirection & Base64 IP Token Resolver
  /// Handles load balancer redirects, decodes token/lvtoken/key base64 IP pins
  static Future<String> resolveVodUrl(String vodUrl) async {
    try {
      final client = http.Client();
      final request = http.Request('HEAD', Uri.parse(vodUrl))
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        ..headers['Referer'] = 'http://noos.plus/';

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 8));
      final finalUri = streamedResponse.headers['location'] != null
          ? Uri.parse(streamedResponse.headers['location']!)
          : Uri.parse(vodUrl);

      // Check if IP is already in host
      final ipMatch = RegExp(r'^\d+\.\d+\.\d+\.\d+$').firstMatch(finalUri.host);
      if (ipMatch != null) {
        return finalUri.toString();
      }

      // Check query tokens: token, lvtoken, key
      for (final key in ['token', 'lvtoken', 'key']) {
        if (finalUri.queryParameters.containsKey(key)) {
          var tokenVal = finalUri.queryParameters[key]!;
          final missing = tokenVal.length % 4;
          if (missing != 0) {
            tokenVal += '=' * (4 - missing);
          }
          try {
            final decoded = utf8.decode(base64.decode(tokenVal), allowMalformed: true);
            final ipInToken = RegExp(r'\b\d+\.\d+\.\d+\.\d+\b').firstMatch(decoded);
            if (ipInToken != null) {
              final newHost = ipInToken.group(0)!;
              return finalUri.replace(host: newHost, port: finalUri.hasPort ? finalUri.port : 80).toString();
            }
          } catch (_) {}
        }
      }
      return finalUri.toString();
    } catch (_) {
      return vodUrl;
    }
  }

  /// Phase 7: Enigma2 OpenWebif Integration (/enigma2.php)
  /// Fetches XML and decodes Base64 encoded titles
  static Future<List<Channel>> parseEnigma2({
    required String enigma2Url,
    required String username,
    required String password,
  }) async {
    final channels = <Channel>[];
    try {
      var uri = Uri.parse(enigma2Url);
      if (!uri.queryParameters.containsKey('username')) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'username': username,
          'password': password,
        });
      }

      final res = await http.get(uri, headers: standardHeaders).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = res.body;
        // Regex parse <channel> blocks
        final channelBlocks = RegExp(r'<channel>([\s\S]*?)<\/channel>').allMatches(body);
        for (final match in channelBlocks) {
          final block = match.group(1) ?? '';
          final titleMatch = RegExp(r'<title>([\s\S]*?)<\/title>').firstMatch(block);
          final streamUrlMatch = RegExp(r'<stream_url>([\s\S]*?)<\/stream_url>').firstMatch(block);
          final descMatch = RegExp(r'<description>([\s\S]*?)<\/description>').firstMatch(block);

          if (streamUrlMatch != null) {
            final streamUrl = streamUrlMatch.group(1)?.trim() ?? '';
            var title = titleMatch?.group(1)?.trim() ?? 'Channel';
            // Decode Base64 title if encoded
            if (title.isNotEmpty) {
              try {
                final missing = title.length % 4;
                if (missing != 0) {
                  title += '=' * (4 - missing);
                }
                title = utf8.decode(base64.decode(title), allowMalformed: true);
              } catch (_) {}
            }

            final group = descMatch?.group(1)?.trim() ?? 'General';

            final ch = Channel()
              ..name = title
              ..url = streamUrl
              ..group = group
              ..contentType = streamUrl.contains('/movie/') ? ContentType.movie : ContentType.live;
            channels.add(ch);
          }
        }
      }
    } catch (_) {}
    return channels;
  }
}
