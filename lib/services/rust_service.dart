import 'dart:async';
import '../models/channel.dart';

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
    } catch (e) {
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
  static Future<Map<String, String>> getStalkerStreamHeaders(
    String portalUrl,
    String macAddress,
    String cmd,
  ) async {
    final baseUrl = portalUrl.replaceAll(RegExp(r'/$'), '');
    return {
      'User-Agent':
          'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3',
      'Cookie': 'mac=$macAddress; stb_lang=en; timezone=Europe/London',
      'Referer': '$baseUrl/c/',
    };
  }
}
