enum ContentType { live, movie, series }

class ChannelModel {
  final String id;
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final ContentType contentType;
  bool isFavorite;
  int playCount;
  DateTime? lastPlayed;
  double rating;
  int watchedMilliseconds;
  int totalMilliseconds;
  final int? playlistId;

  ChannelModel({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.contentType = ContentType.live,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayed,
    this.rating = 0.0,
    this.watchedMilliseconds = 0,
    this.totalMilliseconds = 0,
    this.playlistId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
        'contentType': contentType.name,
        'isFavorite': isFavorite,
        'playCount': playCount,
        'lastPlayed': lastPlayed?.toIso8601String(),
        'rating': rating,
        'watchedMilliseconds': watchedMilliseconds,
        'totalMilliseconds': totalMilliseconds,
        'playlistId': playlistId,
      };

  factory ChannelModel.fromJson(Map<String, dynamic> json) => ChannelModel(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        logo: json['logo'] as String?,
        group: json['group'] as String?,
        contentType: ContentType.values.firstWhere(
          (e) => e.name == json['contentType'],
          orElse: () => ContentType.live,
        ),
        isFavorite: json['isFavorite'] as bool? ?? false,
        playCount: json['playCount'] as int? ?? 0,
        lastPlayed: json['lastPlayed'] != null ? DateTime.parse(json['lastPlayed']) : null,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        watchedMilliseconds: json['watchedMilliseconds'] as int? ?? 0,
        totalMilliseconds: json['totalMilliseconds'] as int? ?? 0,
        playlistId: json['playlistId'] as int?,
      );
}

enum PlaylistSourceType { m3u, xtreamCodes, stalker }

class PlaylistModel {
  final int id;
  final String name;
  final PlaylistSourceType sourceType;
  final String url;
  final String? username;
  final String? password;
  final String? macAddress;
  bool isActive;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.url,
    this.username,
    this.password,
    this.macAddress,
    this.isActive = false,
  });

  bool get isStalker => sourceType == PlaylistSourceType.stalker;
  bool get isXtreamCodes => sourceType == PlaylistSourceType.xtreamCodes;
  bool get isM3u => sourceType == PlaylistSourceType.m3u;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sourceType': sourceType.name,
        'url': url,
        'username': username,
        'password': password,
        'macAddress': macAddress,
        'isActive': isActive,
      };

  factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
        id: json['id'] as int,
        name: json['name'] as String,
        sourceType: PlaylistSourceType.values.firstWhere(
          (e) => e.name == json['sourceType'],
          orElse: () => PlaylistSourceType.m3u,
        ),
        url: json['url'] as String,
        username: json['username'] as String?,
        password: json['password'] as String?,
        macAddress: json['macAddress'] as String?,
        isActive: json['isActive'] as bool? ?? false,
      );
}
