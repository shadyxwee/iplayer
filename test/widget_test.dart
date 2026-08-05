import 'package:flutter_test/flutter_test.dart';
import 'package:riptv/services/m3u_parser.dart';

void main() {
  group('M3UParser Tests', () {
    test('parseString correctly parses valid M3U file', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 tvg-id="1" tvg-name="HBO" tvg-logo="http://logo.com/hbo.png" group-title="Movies",HBO HD
http://stream.com/hbo.ts
#EXTINF:-1 tvg-id="2" tvg-name="CNN" tvg-logo="http://logo.com/cnn.png" group-title="News",CNN International
http://stream.com/cnn.ts
''';

      final channels = M3UParser.parseString(m3uContent);

      expect(channels.length, equals(2));

      expect(channels[0].name, equals('HBO HD'));
      expect(channels[0].url, equals('http://stream.com/hbo.ts'));
      expect(channels[0].group, equals('Movies'));
      expect(channels[0].logo, equals('http://logo.com/hbo.png'));

      expect(channels[1].name, equals('CNN International'));
      expect(channels[1].url, equals('http://stream.com/cnn.ts'));
      expect(channels[1].group, equals('News'));
      expect(channels[1].logo, equals('http://logo.com/cnn.png'));
    });

    test('parseString ignores empty lines and invalid records', () {
      const m3uContent = '''
#EXTM3U

#EXTINF:-1 tvg-id="3" group-title="Sports",Sky Sports
http://stream.com/sky.ts

#INVALID LINE
''';

      final channels = M3UParser.parseString(m3uContent);
      expect(channels.length, equals(1));
      expect(channels[0].name, equals('Sky Sports'));
    });
  });
}
