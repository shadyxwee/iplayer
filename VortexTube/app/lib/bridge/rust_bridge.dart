import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef VtParseM3uNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef VtParseM3uDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef VtNormalizeUrlNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef VtNormalizeUrlDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef VtGetCandidatesNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef VtGetCandidatesDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef VtCleanCmdNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef VtCleanCmdDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef VtCalculateScoreNative = Double Function(Bool, Bool, Int64, Bool, Double);
typedef VtCalculateScoreDart = double Function(bool, bool, int, bool, double);

typedef VtFreeStringNative = Void Function(Pointer<Utf8>);
typedef VtFreeStringDart = void Function(Pointer<Utf8>);

class RustBridge {
  static DynamicLibrary? _lib;
  static bool _initialized = false;

  static VtParseM3uDart? _parseM3u;
  static VtNormalizeUrlDart? _normalizeUrl;
  static VtGetCandidatesDart? _getCandidates;
  static VtCleanCmdDart? _cleanCmd;
  static VtCalculateScoreDart? _calculateScore;
  static VtFreeStringDart? _freeString;

  static List<Map<String, dynamic>> parseM3u(String content) {
    if (_parseM3u != null && _freeString != null) {
      final ptr = content.toNativeUtf8();
      final resPtr = _parseM3u!(ptr);
      final res = resPtr.toDartString();
      _freeString!(resPtr);
      malloc.free(ptr);
      try {
        final list = jsonDecode(res) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    return [];
  }

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libvortextube_backend.so');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libvortextube_backend.so');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libvortextube_backend.dylib');
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('vortextube_backend.dll');
      }
    } catch (_) {
      // Dynamic library can be loaded or fallback to pure Dart implementations
    }

    if (_lib != null) {
      try {
        _parseM3u = _lib!.lookupFunction<VtParseM3uNative, VtParseM3uDart>('vt_parse_m3u');
        _normalizeUrl = _lib!.lookupFunction<VtNormalizeUrlNative, VtNormalizeUrlDart>('vt_normalize_stalker_url');
        _getCandidates = _lib!.lookupFunction<VtGetCandidatesNative, VtGetCandidatesDart>('vt_get_stalker_candidates');
        _cleanCmd = _lib!.lookupFunction<VtCleanCmdNative, VtCleanCmdDart>('vt_clean_cmd');
        _calculateScore = _lib!.lookupFunction<VtCalculateScoreNative, VtCalculateScoreDart>('vt_calculate_score');
        _freeString = _lib!.lookupFunction<VtFreeStringNative, VtFreeStringDart>('vt_free_string');
      } catch (_) {}
    }
  }

  static String normalizeStalkerUrl(String url) {
    if (_normalizeUrl != null && _freeString != null) {
      final ptr = url.toNativeUtf8();
      final resPtr = _normalizeUrl!(ptr);
      final res = resPtr.toDartString();
      _freeString!(resPtr);
      malloc.free(ptr);
      return res;
    }
    // Dart fallback
    var norm = url.trim();
    if (!norm.startsWith('http://') && !norm.startsWith('https://')) {
      norm = 'http://$norm';
    }
    while (norm.endsWith('/')) {
      norm = norm.substring(0, norm.length - 1);
    }
    for (final s in ['/c', '/c/portal.php', '/portal.php', '/index.html', '/server/load.php']) {
      if (norm.endsWith(s)) {
        norm = norm.substring(0, norm.length - s.length);
        while (norm.endsWith('/')) {
          norm = norm.substring(0, norm.length - 1);
        }
      }
    }
    return norm;
  }

  static List<String> getStalkerCandidateEndpoints(String base) {
    if (_getCandidates != null && _freeString != null) {
      final ptr = base.toNativeUtf8();
      final resPtr = _getCandidates!(ptr);
      final res = resPtr.toDartString();
      _freeString!(resPtr);
      malloc.free(ptr);
      try {
        final list = jsonDecode(res) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    final norm = normalizeStalkerUrl(base);
    return [
      '$norm/portal.php',
      '$norm/c/portal.php',
      '$norm/stalker_portal/server/load.php',
      '$norm/server/load.php',
      '$norm/stalker_portal/c/portal.php',
    ];
  }

  static String cleanCmd(String cmd) {
    if (_cleanCmd != null && _freeString != null) {
      final ptr = cmd.toNativeUtf8();
      final resPtr = _cleanCmd!(ptr);
      final res = resPtr.toDartString();
      _freeString!(resPtr);
      malloc.free(ptr);
      return res;
    }
    var cleaned = cmd.trim();
    if (cleaned.startsWith('ffmpeg ')) {
      cleaned = cleaned.substring(7).trim();
    } else if (cleaned.startsWith('auto ')) {
      cleaned = cleaned.substring(5).trim();
    }
    return cleaned;
  }

  static double calculatePersonalizationScore({
    required bool isFavorite,
    required bool inLovedCategory,
    required int playCount,
    required bool hasWatchProgress,
    required double rating,
  }) {
    if (_calculateScore != null) {
      return _calculateScore!(isFavorite, inLovedCategory, playCount, hasWatchProgress, rating);
    }
    var score = 0.0;
    if (isFavorite) score += 500.0;
    if (inLovedCategory) score += 300.0;
    if (hasWatchProgress) score += 150.0;
    score += playCount * 20.0;
    score += rating * 10.0;
    return score;
  }
}
