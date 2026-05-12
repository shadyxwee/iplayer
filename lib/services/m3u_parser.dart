import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class M3UParser {
  static Future<List<Channel>> parseFromUrl(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'IPTVSmartersPlayer'},
    );
    if (response.statusCode == 200) {
      final content = utf8.decode(response.bodyBytes);
      return parseString(content);
    }
    throw Exception('Failed to load M3U');
  }

  static List<Channel> parseString(String content) {
    final lines = LineSplitter.split(content).toList();
    final channels = <Channel>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF:')) {
        // Find the next line that is a URL
        String? url;
        for (int j = i + 1; j < lines.length; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;
          if (nextLine.startsWith('#')) break; // Another tag
          url = nextLine;
          i = j; // Skip to this line
          break;
        }
        
        if (url != null) {
          channels.add(Channel.fromM3U(line, url));
        }
      }
    }
    return channels;
  }

  static Map<String, List<Channel>> groupChannels(List<Channel> channels) {
    final groups = <String, List<Channel>>{};
    for (final channel in channels) {
      final group = channel.group ?? 'Other';
      if (!groups.containsKey(group)) {
        groups[group] = [];
      }
      groups[group]!.add(channel);
    }
    return groups;
  }

  /// Groups channels into a hierarchical structure
  /// Key: Parent group name
  /// Value: Map of Sub-group name to List of Channels
  static Map<String, Map<String, List<Channel>>> groupChannelsHierarchical(List<Channel> channels) {
    final hierarchy = <String, Map<String, List<Channel>>>{};
    
    for (final channel in channels) {
      final fullGroup = channel.group ?? 'Other';
      
      // Try to split by common separators
      String parent = fullGroup;
      String sub = 'All';
      
      final separators = ['|', ' - ', ':', ' / '];
      for (final sep in separators) {
        if (fullGroup.contains(sep)) {
          final parts = fullGroup.split(sep);
          parent = parts[0].trim();
          sub = parts.sublist(1).join(sep).trim();
          break;
        }
      }
      
      if (!hierarchy.containsKey(parent)) {
        hierarchy[parent] = {};
      }
      
      if (!hierarchy[parent]!.containsKey(sub)) {
        hierarchy[parent]![sub] = [];
      }
      
      hierarchy[parent]![sub]!.add(channel);
    }
    
    return hierarchy;
  }
}
