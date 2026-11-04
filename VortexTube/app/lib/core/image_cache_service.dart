import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TVImageCacheService {
  static Directory? _cacheDir;
  static final Map<String, String> _memoryPathCache = {};

  static Future<void> initialize() async {
    if (_cacheDir != null) return;
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${baseDir.path}/tv_posters');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    } catch (_) {}
  }

  static String _hashUrl(String url) {
    var hash = 0;
    for (var i = 0; i < url.length; i++) {
      hash = (31 * hash + url.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  static String? getLocalCachedPath(String url) {
    if (url.trim().isEmpty) return null;
    if (_memoryPathCache.containsKey(url)) {
      return _memoryPathCache[url];
    }
    if (_cacheDir == null) return null;
    final hash = _hashUrl(url);
    final filePath = '${_cacheDir!.path}/$hash.img';
    final file = File(filePath);
    if (file.existsSync() && file.lengthSync() > 0) {
      _memoryPathCache[url] = filePath;
      return filePath;
    }
    return null;
  }

  static ImageProvider getCachedImageProvider(String url) {
    final cachedPath = getLocalCachedPath(url);
    if (cachedPath != null) {
      return FileImage(File(cachedPath));
    }
    return NetworkImage(url);
  }

  static Future<String?> cachePoster(String url) async {
    if (url.trim().isEmpty) return null;
    await initialize();
    if (_cacheDir == null) return null;

    final existing = getLocalCachedPath(url);
    if (existing != null) return existing;

    final hash = _hashUrl(url);
    final filePath = '${_cacheDir!.path}/$hash.img';
    final file = File(filePath);

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        _memoryPathCache[url] = filePath;
        return filePath;
      }
    } catch (_) {}
    return null;
  }
}
