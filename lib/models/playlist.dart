import 'package:isar/isar.dart';

part 'playlist.g.dart';

enum PlaylistSourceType {
  m3u,
  xtreamCodes,
}

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;
  late String url;
  
  // Xtream Codes specific
  String? username;
  String? password;
  
  @enumerated
  late PlaylistSourceType sourceType;

  int channelCount = 0;
  DateTime? lastUpdated;
  String? epgUrl;
  bool isActive = false;

  Playlist();

  bool get isXtreamCodes => sourceType == PlaylistSourceType.xtreamCodes;

  String getFullUrl() {
    if (sourceType == PlaylistSourceType.m3u) {
      return url;
    } else {
      // For Xtream Codes, url is the host
      return '$url/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
    }
  }
}
