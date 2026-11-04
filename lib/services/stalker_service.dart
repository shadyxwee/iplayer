import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';

/// Stalker / Ministra Portal Client Service
/// Implements Best Practice Specification v1.0:
/// - Mandatory Endpoint Auto-Detection
/// - Proper Headers & Cookies (User-Agent, Bearer Auth, MAC, stb_lang, timezone)
/// - Handshake & Token Renewal
/// - MAC Checker (handshake + get_profile / get_main_info)
/// - MAC Player (Live, VOD, Series, and stream link creation)
class StalkerService {
  final String portalUrl;
  final String macAddress;
  final String deviceId;
  final String deviceId2;
  final String signature;
  final String serialNumber;

  String? _activeEndpoint;
  String? _token;

  static const String userAgent =
      'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3';
  static const String stbLang = 'en';
  static const String timezone = 'Europe/London';

  StalkerService({
    required this.portalUrl,
    required this.macAddress,
    this.deviceId = 'MAG254_DEVICE_ID_DEFAULT',
    this.deviceId2 = 'MAG254_DEVICE_ID2_DEFAULT',
    this.signature = 'MAG254_SIGNATURE_DEFAULT',
    this.serialNumber = 'MAG254_SERIAL_DEFAULT',
  });

  /// Step 3.1: Normalize the user-provided Portal URL:
  /// - Remove trailing /c, /c/, /index.html, etc.
  /// - Keep only scheme + host + port + optional base path up to (but not including) /c
  static String normalizeUrl(String rawUrl) {
    var url = rawUrl.trim();

    while (true) {
      final prev = url;
      url = url.replaceAll(RegExp(r'/+$'), '');
      if (url.endsWith('/index.html')) {
        url = url.substring(0, url.length - 11);
      } else if (url.endsWith('/index.php')) {
        url = url.substring(0, url.length - 10);
      } else if (url.endsWith('/c')) {
        url = url.substring(0, url.length - 2);
      } else if (url.endsWith('/stalker_portal/c')) {
        url = url.substring(0, url.length - 17);
      } else if (url.endsWith('/stalker_portal')) {
        url = url.substring(0, url.length - 15);
      }
      if (url == prev) break;
    }

    return url.replaceAll(RegExp(r'/+$'), '');
  }

  /// Step 3.2: Generate candidate endpoints in priority order:
  /// 1. {base}/portal.php
  /// 2. {base}/c/portal.php
  /// 3. {base}/stalker_portal/server/load.php
  /// 4. {base}/server/load.php
  /// 5. {base}/stalker_portal/c/portal.php
  static List<String> candidateEndpoints(String rawUrl) {
    final base = normalizeUrl(rawUrl);
    return [
      '$base/portal.php',
      '$base/c/portal.php',
      '$base/stalker_portal/server/load.php',
      '$base/server/load.php',
      '$base/stalker_portal/c/portal.php',
    ];
  }

  /// Required HTTP headers
  Map<String, String> getHeaders({bool includeAuth = true}) {
    final base = normalizeUrl(portalUrl);
    final headers = <String, String>{
      'User-Agent': userAgent,
      'Connection': 'Keep-Alive',
      'Accept-Encoding': 'gzip',
      'Referer': '$base/c/',
    };

    var cookie = 'mac=$macAddress; stb_lang=$stbLang; timezone=$timezone';
    if (_token != null && _token!.isNotEmpty) {
      cookie += '; token=$_token';
    }
    headers['Cookie'] = cookie;

    if (includeAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Step 3.3 & Step 5: Endpoint Auto-Detection & Handshake
  Future<String> handshake() async {
    if (_activeEndpoint != null) {
      try {
        final tok = await _tryHandshakeEndpoint(_activeEndpoint!);
        _token = tok;
        return tok;
      } catch (_) {
        _activeEndpoint = null;
      }
    }

    final candidates = candidateEndpoints(portalUrl);
    String? lastError;

    for (final candidate in candidates) {
      try {
        final tok = await _tryHandshakeEndpoint(candidate);
        _activeEndpoint = candidate;
        _token = tok;
        return tok;
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception('Failed to detect Stalker portal API endpoint: $lastError');
  }

  Future<String> _tryHandshakeEndpoint(String endpoint) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: {
      'type': 'stb',
      'action': 'handshake',
      'JsHttpRequest': '1-xml',
    });

    final response = await http
        .get(uri, headers: getHeaders(includeAuth: false))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('js')) {
        final js = decoded['js'];
        if (js is Map && js.containsKey('token') && js['token'] != null) {
          final token = js['token'].toString();
          if (token.isNotEmpty) {
            return token;
          }
        }
      }
    }
    throw Exception('Handshake failed at $endpoint with status ${response.statusCode}');
  }

  /// Generic request with token auto-injection and 401 retry
  Future<dynamic> request(Map<String, String> queryParams) async {
    if (_token == null || _activeEndpoint == null) {
      await handshake();
    }

    for (int attempt = 0; attempt < 2; attempt++) {
      final params = Map<String, String>.from(queryParams);
      params['JsHttpRequest'] = '1-xml';

      final uri = Uri.parse(_activeEndpoint!).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: getHeaders(includeAuth: true))
          .timeout(const Duration(seconds: 12));

      if ((response.statusCode == 401 || response.statusCode == 403) && attempt == 0) {
        await handshake();
        continue;
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('js')) {
          final js = decoded['js'];
          if (js is String && (js.contains('authorization') || js.contains('token')) && attempt == 0) {
            await handshake();
            continue;
          }
          return js;
        }
        return decoded;
      }
    }

    throw Exception('Stalker request failed after token renewal retry');
  }

  /// Step 7: MAC Checker
  Future<Map<String, dynamic>> checkMac() async {
    try {
      final tok = await handshake();

      final profileRes = await request({'type': 'stb', 'action': 'get_profile'});

      if (profileRes == null || profileRes == false) {
        return {
          'is_working': false,
          'token': tok,
          'endpoint': _activeEndpoint,
          'message': 'Portal rejected MAC or profile is empty',
        };
      }

      String? expiryDate;
      String? status;
      if (profileRes is Map) {
        expiryDate = profileRes['phone']?.toString() ?? profileRes['expire_billing']?.toString();
        status = profileRes['status']?.toString();
      }

      return {
        'is_working': true,
        'token': tok,
        'endpoint': _activeEndpoint,
        'expiry_date': expiryDate,
        'status': status ?? 'Active',
      };
    } catch (e) {
      return {
        'is_working': false,
        'message': e.toString(),
      };
    }
  }

  /// Live Categories (`type=itv&action=get_genres`)
  Future<Map<String, String>> getLiveCategories() async {
    final categories = <String, String>{};
    try {
      final data = await request({'type': 'itv', 'action': 'get_genres'});
      if (data is List) {
        for (var item in data) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            final title = item['title']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          }
        }
      }
    } catch (_) {}
    return categories;
  }

  /// VOD Categories (`type=vod&action=get_categories`)
  Future<Map<String, String>> getVodCategories() async {
    final categories = <String, String>{};
    try {
      final data = await request({'type': 'vod', 'action': 'get_categories'});
      if (data is List) {
        for (var item in data) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            final title = item['title']?.toString() ?? item['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          }
        }
      }
    } catch (_) {}
    return categories;
  }

  /// Series Categories (`type=series&action=get_categories`)
  Future<Map<String, String>> getSeriesCategories() async {
    final categories = <String, String>{};
    try {
      final data = await request({'type': 'series', 'action': 'get_categories'});
      if (data is List) {
        for (var item in data) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            final title = item['title']?.toString() ?? item['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          }
        }
      }
    } catch (_) {}
    return categories;
  }

  /// Clean command prefix
  static String cleanCmd(String cmd) {
    var c = cmd.trim();
    if (c.startsWith('ffmpeg ')) {
      c = c.substring(7);
    } else if (c.startsWith('auto ')) {
      c = c.substring(5);
    }
    return c.trim();
  }

  /// Helper to fetch all items with pagination support (p=0, p=1, ...)
  Future<List<Map<String, dynamic>>> fetchAllPaginated(String mediaType, {int maxPages = 50}) async {
    final allItems = <Map<String, dynamic>>[];
    for (int p = 0; p < maxPages; p++) {
      final res = await request({
        'type': mediaType,
        'action': 'get_ordered_list',
        'p': p.toString(),
      });

      List items = [];
      if (res is Map && res['data'] is List) {
        items = res['data'] as List;
      } else if (res is List) {
        items = res;
      }

      if (items.isEmpty) {
        break;
      }

      for (var item in items) {
        if (item is Map) {
          allItems.add(Map<String, dynamic>.from(item));
        }
      }

      // If page had fewer items or total_items reached, stop
      if (res is Map && res['total_items'] != null) {
        final total = int.tryParse(res['total_items'].toString()) ?? 0;
        if (allItems.length >= total && total > 0) {
          break;
        }
      }
    }
    return allItems;
  }

  /// Get Live Channels
  Future<Map<String, dynamic>> getLiveChannels() async {
    try {
      final categories = await getLiveCategories();
      final channels = <Channel>[];

      final items = await fetchAllPaginated('itv');

      for (var item in items) {
        final ch = Channel();
        ch.name = item['name']?.toString() ?? 'Unknown Channel';
        final rawCmd = item['cmd']?.toString() ?? '';
        ch.url = cleanCmd(rawCmd);

        final catId = item['tv_genre_id']?.toString() ?? item['category_id']?.toString() ?? '';
        ch.group = categories[catId] ?? 'General';

        ch.logo = item['logo']?.toString();
        ch.number = int.tryParse(item['number']?.toString() ?? '');
        ch.tvgId = int.tryParse(item['id']?.toString() ?? '');
        ch.contentType = ContentType.live;

        // Custom headers for Stalker streaming
        ch.userAgent = userAgent;
        ch.referer = '${normalizeUrl(portalUrl)}/c/';

        channels.add(ch);
      }

      return {
        'success': true,
        'channels': channels,
        'message': 'Loaded ${channels.length} live channels',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching live channels: $e',
      };
    }
  }

  /// Get Movies (VOD)
  Future<Map<String, dynamic>> getMovies() async {
    try {
      final categories = await getVodCategories();
      final movies = <VodItem>[];

      final items = await fetchAllPaginated('vod');

      for (var item in items) {
        final streamId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
        final name = item['name']?.toString() ?? 'Unknown Movie';
        final catId = item['category_id']?.toString() ?? '';
        final catName = categories[catId] ?? 'Movies';
        final poster = item['screenshot_uri']?.toString() ?? item['poster']?.toString();
        final plot = item['description']?.toString() ?? item['descr']?.toString();

        final vod = VodItem(
          streamId: streamId,
          name: name,
          streamIcon: poster,
          baseUrl: portalUrl,
          username: macAddress,
          password: '',
          containerExtension: 'ts',
          categoryName: catName,
          plot: plot,
        );
        movies.add(vod);
      }

      return {
        'success': true,
        'movies': movies,
        'message': 'Loaded ${movies.length} movies',
      };
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
      final categories = await getSeriesCategories();
      final seriesList = <SeriesItem>[];

      final items = await fetchAllPaginated('series');

      for (var item in items) {
        final id = item['id']?.toString() ?? '';
        final name = item['name']?.toString() ?? 'Unknown Series';
        final catId = item['category_id']?.toString() ?? '';
        final catName = categories[catId] ?? 'Series';
        final poster = item['screenshot_uri']?.toString() ?? item['poster']?.toString();
        final plot = item['description']?.toString() ?? item['descr']?.toString();

        final series = SeriesItem(
          seriesId: int.tryParse(id) ?? 0,
          name: name,
          categoryName: catName,
          cover: poster,
          plot: plot,
        );
        seriesList.add(series);
      }

      return {
        'success': true,
        'series': seriesList,
        'message': 'Loaded ${seriesList.length} series',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching series: $e',
      };
    }
  }

  /// Get Series info and episodes
  Future<Map<String, dynamic>> getSeriesInfo(String seriesId) async {
    try {
      final res = await request({
        'type': 'series',
        'action': 'get_ordered_list',
        'movie_id': seriesId,
        'category': '*',
      });

      List items = [];
      if (res is Map && res['data'] is List) {
        items = res['data'] as List;
      } else if (res is List) {
        items = res;
      }

      final episodes = <Map<String, dynamic>>[];
      for (var item in items) {
        if (item is Map) {
          episodes.add({
            'id': item['id'],
            'title': item['name'] ?? 'Episode',
            'episode_num': item['series'] ?? item['episode'] ?? '1',
            'cmd': item['cmd'] ?? '',
            'url': cleanCmd(item['cmd']?.toString() ?? ''),
          });
        }
      }

      return {
        'success': true,
        'data': {
          'episodes': {'1': episodes},
          'seasons': [{'season_number': '1'}],
        },
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Step 8.4: Create stream link
  Future<Map<String, dynamic>> createLink(String cmd, {String type = 'itv'}) async {
    try {
      final res = await request({
        'type': type,
        'action': 'create_link',
        'cmd': cmd,
      });

      var streamUrl = cleanCmd(cmd);
      if (res is Map && res['cmd'] != null) {
        streamUrl = cleanCmd(res['cmd'].toString());
      }

      return {
        'success': true,
        'stream_url': streamUrl,
        'headers': getHeaders(includeAuth: true),
      };
    } catch (e) {
      return {
        'success': false,
        'stream_url': cleanCmd(cmd),
        'headers': getHeaders(includeAuth: true),
        'error': e.toString(),
      };
    }
  }
}
