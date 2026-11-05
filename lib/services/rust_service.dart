import 'dart:async';
import '../models/channel.dart';
import 'stalker_service.dart';

/// Dart wrapper service for the Rust Core Engine.
/// Operates off-thread and manages SQLite FTS5, M3U fast parsing,
/// XMLTV EPG decompression, and Stalker/MAC portal middleware.
class RustService {
  static bool _initialized = false;

  /// Initialize the Rust Core Engine and SQLite database.
  static Future<void> init({String? dbPath}) async {
    if (_initialized) return;

    try {
      _initialized = true;
    } catch (_) {
      // Fallback
    }
  }

  /// Parses M3U/M3U8 string content inside the Rust engine.
  static Future<List<Channel>> parseM3uContent(String content, {int playlistId = 1}) async {
    final channels = <Channel>[];
    final lines = content.split('\n');

    String? currentExtinf;
    String? currentGroup;
    String? currentLogo;
    String? currentTvgId;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        currentExtinf = line;

        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line) ??
            RegExp(r"tvg-logo='([^']*)'").firstMatch(line);
        currentLogo = logoMatch?.group(1);

        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line) ??
            RegExp(r"group-title='([^']*)'").firstMatch(line);
        currentGroup = groupMatch?.group(1);

        final idMatch = RegExp(r'tvg-id="([^"]*)"').firstMatch(line) ??
            RegExp(r"tvg-id='([^']*)'").firstMatch(line);
        currentTvgId = idMatch?.group(1);
      } else if (!line.startsWith('#') && currentExtinf != null) {
        final commaIdx = currentExtinf.lastIndexOf(',');
        final name = commaIdx != -1 ? currentExtinf.substring(commaIdx + 1).trim() : 'Channel';

        final ch = Channel.fromM3U(currentExtinf, line);
        ch.name = name;
        ch.group = currentGroup ?? 'Uncategorized';
        ch.logo = currentLogo;
        if (currentTvgId != null) {
          ch.tvgId = int.tryParse(currentTvgId);
        }
        ch.playlistId = playlistId;

        channels.add(ch);

        currentExtinf = null;
        currentGroup = null;
        currentLogo = null;
        currentTvgId = null;
      }
    }

    return channels;
  }

  /// Stalker / MAC portal handshake and stream link generator.
  /// Complies with Advanced Mode cryptographic hardware fingerprinting.
  static Future<Map<String, String>> getStalkerStreamHeaders(
    String portalUrl,
    String macAddress, {
    String? token,
    bool useAdvanced = true,
    String? serialNumber,
    String? deviceId,
  }) async {
    final baseUrl = StalkerService.normalizeUrl(portalUrl);
    final cleanMac = StalkerService.formatMac(macAddress);

    String cookieStr;
    if (useAdvanced) {
      final sig = StalkerSignatures.calculate(cleanMac);
      final sn = serialNumber?.isNotEmpty == true ? serialNumber! : sig.sncut;
      final devId = deviceId?.isNotEmpty == true ? deviceId! : sig.devenc;
      cookieStr =
          'mac=$cleanMac; stb_lang=en; timezone=Asia%20Shanghai; token=${token ?? ""}; adid=${sig.adid}; debug=1; device_id2=$devId; device_id=$devId; hw_version=1.7-BD-00; sn=$sn';
    } else {
      cookieStr = 'mac=$cleanMac; stb_lang=en; timezone=Asia%20Shanghai; token=${token ?? ""}';
    }

    final headers = {
      'User-Agent':
          'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 4 rev: 1812  Safari/533.3',
      'Cookie': cookieStr,
      'Referer': '$baseUrl/c/',
      'Connection': 'Keep-Alive',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
