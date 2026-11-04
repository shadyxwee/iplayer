import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortextube/core/models.dart';
import 'package:vortextube/core/storage_service.dart';
import 'package:vortextube/bridge/rust_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VortexTube StorageService & Seeding Tests', () {
    test('initializes default playlists and favorite categories on first launch', () async {
      final playlists = await StorageService.getPlaylists();
      expect(playlists.isNotEmpty, isTrue);
      expect(playlists.any((p) => p.name == 'MAC1' && p.isStalker), isTrue);
      expect(playlists.any((p) => p.name == 'benz44.xyz' && p.isXtreamCodes), isTrue);

      final favorites = await StorageService.getFavoriteCategories();
      expect(favorites.contains('Action & Adventure'), isTrue);
      expect(favorites.contains('Live Sports 4K'), isTrue);

      final channels = await StorageService.getChannels();
      expect(channels.isNotEmpty, isTrue);
    });

    test('can toggle favorite category', () async {
      await StorageService.getPlaylists(); // Seed
      final initialFavorites = await StorageService.getFavoriteCategories();
      expect(initialFavorites.contains('Anime Special'), isFalse);

      await StorageService.toggleFavoriteCategory('Anime Special');
      final updated = await StorageService.getFavoriteCategories();
      expect(updated.contains('Anime Special'), isTrue);

      await StorageService.toggleFavoriteCategory('Anime Special');
      final reverted = await StorageService.getFavoriteCategories();
      expect(reverted.contains('Anime Special'), isFalse);
    });

    test('can save and activate playlists', () async {
      final playlists = await StorageService.getPlaylists(); // Seed
      final newPlaylist = PlaylistModel(
        id: 99,
        name: 'My Stalker Portal',
        sourceType: PlaylistSourceType.stalker,
        url: 'http://test-stalker.com/c/',
        macAddress: '00:1A:79:AB:CD:EF',
        isActive: false,
      );

      final updatedList = List<PlaylistModel>.from(playlists)..add(newPlaylist);
      await StorageService.savePlaylists(updatedList);

      var all = await StorageService.getPlaylists();
      expect(all.any((p) => p.id == 99), isTrue);

      await StorageService.setActivePlaylistId(99);
      all = await StorageService.getPlaylists();
      final active = all.firstWhere((p) => p.isActive);
      expect(active.id, equals(99));
    });
  });

  group('VortexTube RustBridge Dart Fallback Tests', () {
    test('normalizes stalker url properly', () {
      final normalized = RustBridge.normalizeStalkerUrl('http://iptv.example.com/c/portal.php');
      expect(normalized, equals('http://iptv.example.com'));

      final normalized2 = RustBridge.normalizeStalkerUrl('http://stalker.server.org:8080/stalker_portal/c/');
      expect(normalized2, equals('http://stalker.server.org:8080/stalker_portal'));
    });

    test('generates candidate endpoints in exact priority order', () {
      final candidates = RustBridge.getStalkerCandidateEndpoints('http://test.com/c/');
      expect(candidates, equals([
        'http://test.com/portal.php',
        'http://test.com/c/portal.php',
        'http://test.com/stalker_portal/server/load.php',
        'http://test.com/server/load.php',
        'http://test.com/stalker_portal/c/portal.php',
      ]));
    });

    test('cleans ffmpeg / auto prefix from stream cmd', () {
      expect(RustBridge.cleanCmd('ffmpeg http://server.com/live/1.ts'), equals('http://server.com/live/1.ts'));
      expect(RustBridge.cleanCmd('auto http://server.com/live/2.ts'), equals('http://server.com/live/2.ts'));
      expect(RustBridge.cleanCmd('http://server.com/live/3.ts'), equals('http://server.com/live/3.ts'));
    });

    test('calculates personalization score', () {
      final scoreLoved = RustBridge.calculatePersonalizationScore(
        isFavorite: true,
        inLovedCategory: true,
        playCount: 5,
        hasWatchProgress: true,
        rating: 9.0,
      );
      // 500 (fav) + 300 (loved cat) + 150 (progress) + 5*20 (100) + 9*10 (90) = 1140
      expect(scoreLoved, equals(1140.0));
    });
  });
}
