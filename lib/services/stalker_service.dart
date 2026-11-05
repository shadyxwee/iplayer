import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';

/// Cryptographic hardware fingerprint signatures for bypassing anti-tamper middleware
class StalkerSignatures {
  final String adid;
  final String sncut;
  final String devenc;
  final String devenc2;
  final String signature;

  const StalkerSignatures({
    required this.adid,
    required this.sncut,
    required this.devenc,
    required this.devenc2,
    required this.signature,
  });

  static StalkerSignatures calculate(String macAddress) {
    final bytes = utf8.encode(macAddress);
    final adid = sha1.convert(bytes).toString();
    final snFull = md5.convert(bytes).toString().toUpperCase();
    final sncut = snFull.length >= 13 ? snFull.substring(0, 13) : snFull;
    final devenc = sha256.convert(bytes).toString().toUpperCase();
    final devenc2 = sha256.convert(utf8.encode(sncut)).toString().toUpperCase();

    final sigPayload = '$sncut+$macAddress';
    final sig = sha256.convert(utf8.encode(sigPayload)).toString().toUpperCase();

    return StalkerSignatures(
      adid: adid,
      sncut: sncut,
      devenc: devenc,
      devenc2: devenc2,
      signature: sig,
    );
  }
}

/// Comprehensive Stalker / Ministra MAC IPTV Player Service
/// Implements the complete Ministra & Stalker protocol:
/// - Exact URL suffix normalization and prioritization
/// - Basic, SN-ID, and Advanced Cryptographic signatures
/// - GET / POST Handshake probing with prehash/token parameter differences
/// - Session initialization with get_modules activation
/// - Direct playback vs. create_link resolution with ffmpeg stripping
/// - Pagination for Live, VOD, and Series
class StalkerService {
  final String portalUrl;
  final String macAddress;
  final bool useAdvanced;
  final String? serialNumber;
  final String? deviceId;
  final String? deviceId2;
  final String? signature;

  String? _activeEndpoint;
  String? _token;
  DateTime? _tokenTimestamp;

  static const String userAgent =
      'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 4 rev: 1812  Safari/533.3';
  static const String stbLang = 'en';
  static const String timezone = 'Asia%20Shanghai';

  StalkerService({
    required this.portalUrl,
    required String macAddress,
    this.useAdvanced = true,
    this.serialNumber,
    this.deviceId,
    this.deviceId2,
    this.signature,
  }) : macAddress = formatMac(macAddress);

  /// Sanitize MAC address to XX:XX:XX:XX:XX:XX uppercase
  static String formatMac(String mac) {
    final clean = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (clean.length == 12) {
      final parts = <String>[];
      for (int i = 0; i < 12; i += 2) {
        parts.add(clean.substring(i, i + 2));
      }
      return parts.join(':');
    }
    return mac.toUpperCase();
  }

  /// Phase 1: URL Normalization:
  /// Recursively strip known suffixes down to root host/base path
  static String normalizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    final uri = Uri.parse(url);
    var path = uri.path;
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    const suffixes = [
      '/c/index.html',
      '/c/index.php',
      '/index.html',
      '/index.php',
      '/stalker_portal/server/load.php',
      '/stalker_portal/c/portal.php',
      '/stalker_portal/c',
      '/stalker_portal',
      '/c/portal.php',
      '/server/load.php',
      '/portal.php',
      '/load.php',
      '/c',
    ];

    bool changed = true;
    while (changed) {
      changed = false;
      for (final s in suffixes) {
        if (path.endsWith(s)) {
          path = path.substring(0, path.length - s.length);
          if (path.endsWith('/')) path = path.substring(0, path.length - 1);
          changed = true;
          break;
        }
      }
    }

    final portStr = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portStr$path';
  }

  /// Generate candidate endpoints in priority order
  static List<String> candidateEndpoints(String rawUrl) {
    final cleanRaw = rawUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final base = normalizeUrl(rawUrl);

    final candidates = <String>[];

    // Priority 0: Explicit endpoint if user directly gave a .php script
    if (cleanRaw.endsWith('.php')) {
      candidates.add(cleanRaw);
    }

    candidates.addAll([
      '$base/portal.php',
      '$base/c/portal.php',
      '$base/stalker_portal/server/load.php',
      '$base/server/load.php',
      '$base/stalker_portal/c/portal.php',
    ]);

    final seen = <String>{};
    final dedup = <String>[];
    for (final c in candidates) {
      if (seen.add(c)) {
        dedup.add(c);
      }
    }
    return dedup;
  }

  /// Resolve real serial and device_id (prevent using literal "DEFAULT" strings)
  (String, String) _resolveHardwareIds(StalkerSignatures sig) {
    final sn = (serialNumber != null &&
            serialNumber!.trim().isNotEmpty &&
            !serialNumber!.contains('DEFAULT'))
        ? serialNumber!
        : sig.sncut;

    final dev = (deviceId != null &&
            deviceId!.trim().isNotEmpty &&
            !deviceId!.contains('DEFAULT'))
        ? deviceId!
        : sig.devenc;

    return (sn, dev);
  }

  /// Build Cookie string matching Vortex IPTV Suite specifications
  String _buildCookieString([String? tok]) {
    final t = tok ?? _token ?? '';
    final sig = StalkerSignatures.calculate(macAddress);
    final (sn, dev) = _resolveHardwareIds(sig);

    if (useAdvanced) {
      return 'mac=$macAddress; stb_lang=$stbLang; timezone=$timezone; token=$t; adid=${sig.adid}; debug=1; device_id2=$dev; device_id=$dev; hw_version=1.7-BD-00; sn=$sn';
    }
    return 'mac=$macAddress; stb_lang=$stbLang; timezone=$timezone; token=$t';
  }

  /// Required HTTP headers
  Map<String, String> getHeaders({bool includeAuth = true}) {
    final base = normalizeUrl(portalUrl);
    final headers = <String, String>{
      'User-Agent': userAgent,
      'Referer': '$base/c/',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip',
      'Connection': 'Keep-Alive',
      'Cookie': _buildCookieString(_token),
    };

    if (includeAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Handshake & Session Negotiation:
  /// Iterates through candidate endpoints and falls back between GET and POST
  Future<String> handshake() async {
    // If we have a working active endpoint and fresh token (< 9 minutes old), reuse
    if (_activeEndpoint != null && _token != null && _tokenTimestamp != null) {
      final age = DateTime.now().difference(_tokenTimestamp!).inSeconds;
      if (age < 540) {
        return _token!;
      }
    }

    final candidates = _activeEndpoint != null
        ? [_activeEndpoint!, ...candidateEndpoints(portalUrl)]
        : candidateEndpoints(portalUrl);

    String? lastError;

    for (final endpoint in candidates) {
      final isLoadPhp = endpoint.contains('load.php');
      final handshakeGetUrl = isLoadPhp
          ? '$endpoint?type=stb&action=handshake&prehash=false&JsHttpRequest=1-xml'
          : '$endpoint?type=stb&action=handshake&token=&JsHttpRequest=1-xml';

      // 1. Try GET
      try {
        final headers = getHeaders(includeAuth: false);
        final res = await http.get(Uri.parse(handshakeGetUrl), headers: headers).timeout(const Duration(seconds: 8));

        String? extractedToken;
        if (res.statusCode == 200) {
          extractedToken = _extractToken(res.body);
        }

        // 2. Try POST fallback if GET failed
        if (extractedToken == null || ['UDONTHAVEACCESS', 'INVALID', 'ERROR', 'FAILED'].contains(extractedToken.toUpperCase())) {
          final postHeaders = Map<String, String>.from(headers);
          postHeaders['Content-Type'] = 'application/x-www-form-urlencoded; charset=utf-8';
          final sig = StalkerSignatures.calculate(macAddress);
          final (sn, dev) = _resolveHardwareIds(sig);
          final postBody = {
            'type': 'stb',
            'action': 'handshake',
            'JsHttpRequest': '1-xml',
            'sn': sn,
            'id1': dev,
          };
          final postRes = await http.post(Uri.parse(endpoint), headers: postHeaders, body: postBody).timeout(const Duration(seconds: 6));
          if (postRes.statusCode == 200) {
            extractedToken = _extractToken(postRes.body);
          }
        }

        if (extractedToken != null &&
            !['UDONTHAVEACCESS', 'INVALID', 'ERROR', 'FAILED'].contains(extractedToken.toUpperCase())) {
          _activeEndpoint = endpoint;
          _token = extractedToken;
          _tokenTimestamp = DateTime.now();

          // Phase 3.4: Mandatory session initialization with get_modules
          await _activateSession(endpoint, extractedToken);
          return extractedToken;
        } else if (extractedToken != null) {
          lastError = 'Server returned: $extractedToken';
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      }
    }

    throw Exception('Failed to handshake with Stalker portal: ${lastError ?? "all candidate endpoints failed"}');
  }

  /// Activate token session on server by calling get_modules
  Future<void> _activateSession(String endpoint, String tok) async {
    try {
      final uri = Uri.parse('$endpoint?type=stb&action=get_modules&JsHttpRequest=1-xml');
      final headers = getHeaders(includeAuth: true);
      headers['Cookie'] = _buildCookieString(tok);
      headers['Authorization'] = 'Bearer $tok';
      await http.get(uri, headers: headers).timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  /// Robust layered token extraction
  static String? _extractToken(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded.containsKey('js')) {
        final js = decoded['js'];
        if (js is Map && js.containsKey('token') && js['token'] != null) {
          final t = js['token'].toString().trim();
          if (t.isNotEmpty) return t;
        }
      }
    } catch (_) {}

    final m1 = RegExp(r'"token"\s*:\s*"([^"]+)"').firstMatch(body);
    if (m1 != null) return m1.group(1);

    final m2 = RegExp(r'token":"([^"]+)').firstMatch(body);
    if (m2 != null) return m2.group(1);

    final m3 = RegExp(r'js\s*:\s*\{\s*"token"\s*:\s*"([^"]+)"').firstMatch(body);
    if (m3 != null) return m3.group(1);

    return null;
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
      final res = await request({'type': 'itv', 'action': 'get_genres'});
      dynamic data = res;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is List) {
        for (var item in data) {
          if (item is Map) {
            final id = item['id']?.toString() ?? item['category_id']?.toString() ?? '';
            final title = item['title']?.toString() ?? item['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          }
        }
      } else if (data is Map) {
        // Stalker portals often return map keyed by category ID
        data.forEach((key, val) {
          if (val is Map) {
            final id = val['id']?.toString() ?? val['category_id']?.toString() ?? key.toString();
            final title = val['title']?.toString() ?? val['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          } else if (val is String) {
            categories[key.toString()] = val;
          }
        });
      }
    } catch (_) {}
    return categories;
  }

  /// VOD Categories (`type=vod&action=get_categories`)
  Future<Map<String, String>> getVodCategories() async {
    final categories = <String, String>{};
    try {
      final res = await request({'type': 'vod', 'action': 'get_categories'});
      dynamic data = res;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is List) {
        for (var item in data) {
          if (item is Map) {
            final id = item['id']?.toString() ?? item['category_id']?.toString() ?? '';
            final title = item['title']?.toString() ?? item['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          }
        }
      } else if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            final id = val['id']?.toString() ?? val['category_id']?.toString() ?? key.toString();
            final title = val['title']?.toString() ?? val['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          } else if (val is String) {
            categories[key.toString()] = val;
          }
        });
      }
    } catch (_) {}
    return categories;
  }

  /// Series Categories (`type=series&action=get_categories`)
  Future<Map<String, String>> getSeriesCategories() async {
    final categories = <String, String>{};
    try {
      final res = await request({'type': 'series', 'action': 'get_categories'});
      dynamic data = res;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is List) {
        for (var item in data) {
          if (item is Map) {
            final id = item['id']?.toString() ?? item['category_id']?.toString() ?? '';
            final title = item['title']?.toString() ?? item['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          }
        }
      } else if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            final id = val['id']?.toString() ?? val['category_id']?.toString() ?? key.toString();
            final title = val['title']?.toString() ?? val['category_name']?.toString() ?? 'Unknown';
            if (id.isNotEmpty) {
              categories[id] = title;
            }
          } else if (val is String) {
            categories[key.toString()] = val;
          }
        });
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

  /// Helper to fetch all items with fast concurrent pagination support
  /// Phase 5 Algorithm: Requests page 0, calculates total_pages, and fetches concurrent worker batches (pool size: 3-5)
  Future<List<Map<String, dynamic>>> fetchAllPaginated(
    String mediaType, {
    void Function(String msg, int count)? onProgress,
    int maxPages = 100,
  }) async {
    final allItems = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    // 1. Fetch initial page (p=0)
    final res0 = await request({
      'type': mediaType,
      'action': 'get_ordered_list',
      'p': '0',
    });

    List page0Items = [];
    int totalItems = 0;
    int itemsPerPage = 14;

    if (res0 is Map) {
      if (res0['data'] is List) {
        page0Items = res0['data'] as List;
      }
      if (res0['total_items'] != null) {
        totalItems = int.tryParse(res0['total_items'].toString()) ?? 0;
      }
      if (res0['max_page_items'] != null) {
        itemsPerPage = int.tryParse(res0['max_page_items'].toString()) ?? 14;
      }
    } else if (res0 is List) {
      page0Items = res0;
    }

    for (var item in page0Items) {
      if (item is Map) {
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty || seenIds.add(id)) {
          allItems.add(Map<String, dynamic>.from(item));
        }
      }
    }

    if (onProgress != null) {
      onProgress('Page 1 loaded (${allItems.length} items)', allItems.length);
    }

    if (allItems.isEmpty) {
      return allItems;
    }

    // 2. Calculate remaining pages
    if (itemsPerPage <= 0) itemsPerPage = allItems.isNotEmpty ? allItems.length : 14;
    int totalPages = totalItems > 0 ? ((totalItems + itemsPerPage - 1) ~/ itemsPerPage) : 1;
    if (totalPages > maxPages) totalPages = maxPages;

    if (totalPages <= 1) {
      return allItems;
    }

    // 3. Concurrently fetch remaining pages in worker pools of 4 concurrent requests
    const int poolSize = 4;
    final remainingPages = [for (int p = 1; p < totalPages; p++) p];

    for (int i = 0; i < remainingPages.length; i += poolSize) {
      final batch = remainingPages.sublist(i, (i + poolSize).clamp(0, remainingPages.length));
      final futures = batch.map((p) async {
        try {
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
          return items;
        } catch (_) {
          return [];
        }
      });

      final results = await Future.wait(futures);
      int addedInBatch = 0;
      for (final items in results) {
        for (var item in items) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            if (id.isEmpty || seenIds.add(id)) {
              allItems.add(Map<String, dynamic>.from(item));
              addedInBatch++;
            }
          }
        }
      }

      if (onProgress != null) {
        final currentPage = batch.last + 1;
        onProgress('Pages up to $currentPage/$totalPages loaded (${allItems.length} items)', allItems.length);
      }

      // Early stop if no items were added in this entire batch
      if (addedInBatch == 0 && i > 0) {
        break;
      }
      if (totalItems > 0 && allItems.length >= totalItems) {
        break;
      }
    }

    return allItems;
  }

  /// Get Live Channels with real-time progress reporting
  Future<Map<String, dynamic>> getLiveChannels({void Function(String msg, int count)? onProgress}) async {
    try {
      if (onProgress != null) onProgress('Loading Live TV categories...', 0);
      final categories = await getLiveCategories();
      final channels = <Channel>[];

      final items = await fetchAllPaginated('itv', onProgress: onProgress);

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

  /// Get Movies (VOD) with real-time progress reporting
  Future<Map<String, dynamic>> getMovies({void Function(String msg, int count)? onProgress}) async {
    try {
      if (onProgress != null) onProgress('Loading Movies / VOD categories...', 0);
      final categories = await getVodCategories();
      final movies = <VodItem>[];

      final items = await fetchAllPaginated('vod', onProgress: onProgress);

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

  /// Get Series with real-time progress reporting
  Future<Map<String, dynamic>> getSeries({void Function(String msg, int count)? onProgress}) async {
    try {
      if (onProgress != null) onProgress('Loading Series categories...', 0);
      final categories = await getSeriesCategories();
      final seriesList = <SeriesItem>[];

      final items = await fetchAllPaginated('series', onProgress: onProgress);

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

  /// Phase 6: Stream Playback & Link Resolution
  /// Handles /ch/..._ indirection, creates authenticated link via create_link, and strips ffmpeg prefix
  Future<String> createStreamLink(String cmd, {String type = 'itv', String? episodeNumber}) async {
    var rawCmd = cleanCmd(cmd);

    // If channel doesn't require indirection and is direct, play directly
    if (type == 'itv' && (!rawCmd.contains('/ch/') || !rawCmd.endsWith('_'))) {
      return rawCmd;
    }

    try {
      final params = <String, String>{
        'type': type,
        'action': 'create_link',
        'cmd': rawCmd,
      };
      if (episodeNumber != null && episodeNumber.isNotEmpty) {
        params['series'] = episodeNumber;
      }

      final res = await request(params);

      var streamUrl = rawCmd;
      if (res is Map && res['cmd'] != null) {
        streamUrl = cleanCmd(res['cmd'].toString());
      }
      return streamUrl;
    } catch (_) {
      return rawCmd;
    }
  }

  /// Step 8.4: Create stream link (backward compatible map signature)
  Future<Map<String, dynamic>> createLink(String cmd, {String type = 'itv'}) async {
    try {
      final resolvedUrl = await createStreamLink(cmd, type: type);
      return {
        'success': true,
        'stream_url': resolvedUrl,
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
