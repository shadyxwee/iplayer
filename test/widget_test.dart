import 'package:flutter_test/flutter_test.dart';
import 'package:riptv/services/m3u_parser.dart';

void main() {
  // Required to support compute Isolate calling in unit tests
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('parseStringAsync performs Isolate-based asynchronous parsing', () async {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 tvg-id="4" group-title="Entertainment",Fox Channel
http://stream.com/fox.ts
''';

      final channels = await M3UParser.parseStringAsync(m3uContent);
      expect(channels.length, equals(1));
      expect(channels[0].name, equals('Fox Channel'));
      expect(channels[0].group, equals('Entertainment'));
    });

    test('Channel.fromM3U robustly parses double, single, or unquoted attributes', () {
      // Double quotes
      const lineDouble = '#EXTINF:-1 tvg-id="42" tvg-logo="http://logo.com/42.png" group-title="SciFi",SciFi channel';
      final chanDouble = M3UParser.parseString('$lineDouble\nhttp://scifi.ts')[0];
      expect(chanDouble.tvgId, equals(42));
      expect(chanDouble.logo, equals('http://logo.com/42.png'));
      expect(chanDouble.group, equals('SciFi'));

      // Single quotes
      const lineSingle = "#EXTINF:-1 tvg-id='99' tvg-logo='http://logo.com/99.png' group-title='Action',Action channel";
      final chanSingle = M3UParser.parseString("$lineSingle\nhttp://action.ts")[0];
      expect(chanSingle.tvgId, equals(99));
      expect(chanSingle.logo, equals('http://logo.com/99.png'));
      expect(chanSingle.group, equals('Action'));

      // Unquoted values
      const lineUnquoted = "#EXTINF:-1 tvg-id=101 tvg-logo=http://logo.com/101.png group-title=Comedy,Comedy channel";
      final chanUnquoted = M3UParser.parseString("$lineUnquoted\nhttp://comedy.ts")[0];
      expect(chanUnquoted.tvgId, equals(101));
      expect(chanUnquoted.logo, equals('http://logo.com/101.png'));
      expect(chanUnquoted.group, equals('Comedy'));
    });
  });
}
