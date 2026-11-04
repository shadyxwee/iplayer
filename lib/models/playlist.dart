import 'package:isar/isar.dart';

part 'playlist.g.dart';

enum PlaylistSourceType {
  m3u,
  xtreamCodes,
  stalker,
}

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;
  late String url;
  
  // Xtream Codes specific
  String? username;
  String? password;

  // Stalker / MAC portal specific
  String? macAddress;
  String? serialNumber;
  String? deviceId;
  String? deviceId2;
  String? signature;
  
  @enumerated
  late PlaylistSourceType sourceType;

  int channelCount = 0;
  DateTime? lastUpdated;
  String? epgUrl;
  bool isActive = false;

  Playlist();

  bool get isXtreamCodes => sourceType == PlaylistSourceType.xtreamCodes;
  bool get isStalker => sourceType == PlaylistSourceType.stalker;

  String getFullUrl() {
    if (sourceType == PlaylistSourceType.m3u) {
      return url;
    } else if (sourceType == PlaylistSourceType.xtreamCodes) {
      // For Xtream Codes, url is the host
      return '$url/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
    } else {
      // For Stalker portal, base URL
      return url;
    }
  }
}
