import 'package:flutter_test/flutter_test.dart';
import 'package:riptv/models/playlist.dart';
import 'package:riptv/services/stalker_service.dart';

void main() {
  group('Stalker Service Tests', () {
    test('normalizeUrl cleans trailing /c, /c/, index.html correctly', () {
      expect(
        StalkerService.normalizeUrl('http://example.com/c/'),
        'http://example.com',
      );
      expect(
        StalkerService.normalizeUrl('http://example.com/c'),
        'http://example.com',
      );
      expect(
        StalkerService.normalizeUrl('http://example.com/stalker_portal/c/'),
        'http://example.com',
      );
      expect(
        StalkerService.normalizeUrl('http://example.com/index.html'),
        'http://example.com',
      );
      expect(
        StalkerService.normalizeUrl('http://portal.example.com:8080/portal/c/'),
        'http://portal.example.com:8080/portal',
      );
    });

    test('candidateEndpoints returns expected endpoints in priority order', () {
      final endpoints = StalkerService.candidateEndpoints('http://example.com/c/');
      expect(endpoints.length, 5);
      expect(endpoints[0], 'http://example.com/portal.php');
      expect(endpoints[1], 'http://example.com/c/portal.php');
      expect(endpoints[2], 'http://example.com/stalker_portal/server/load.php');
      expect(endpoints[3], 'http://example.com/server/load.php');
      expect(endpoints[4], 'http://example.com/stalker_portal/c/portal.php');
    });

    test('cleanCmd removes ffmpeg and auto prefixes', () {
      expect(
        StalkerService.cleanCmd('ffmpeg http://stream.tv/live.ts'),
        'http://stream.tv/live.ts',
      );
      expect(
        StalkerService.cleanCmd('auto http://stream.tv/live.m3u8'),
        'http://stream.tv/live.m3u8',
      );
      expect(
        StalkerService.cleanCmd('http://stream.tv/live.ts'),
        'http://stream.tv/live.ts',
      );
    });

    test('Playlist model correctly handles Stalker type and fields', () {
      final playlist = Playlist()
        ..name = 'My Stalker Portal'
        ..url = 'http://example.com/c/'
        ..sourceType = PlaylistSourceType.stalker
        ..macAddress = '00:1A:79:00:11:22'
        ..serialNumber = 'MAG254_SN'
        ..deviceId = 'MAG254_DEV';

      expect(playlist.isStalker, isTrue);
      expect(playlist.isXtreamCodes, isFalse);
      expect(playlist.macAddress, '00:1A:79:00:11:22');
      expect(playlist.serialNumber, 'MAG254_SN');
      expect(playlist.deviceId, 'MAG254_DEV');
      expect(playlist.getFullUrl(), 'http://example.com/c/');
    });
  });
}
