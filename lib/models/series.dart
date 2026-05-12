import 'media_metadata.dart';

class Series {
  String? id; // Xtream series_id
  int? playlistId;
  late String name;
  String? logo;
  String? poster;
  String? backdrop;
  String? plot;
  String? group;
  double? rating;
  List<Season> seasons = [];
  String? get cover => poster ?? logo;
  MediaMetadata? metadata;
  
  Series({
    this.id,
    this.playlistId,
    required this.name,
    this.logo,
    this.poster,
    this.backdrop,
    this.plot,
    this.group,
    this.rating,
    this.seasons = const [],
    this.metadata,
  });
}

class Season {
  final int seasonNumber;
  final List<Episode> episodes;

  Season({required this.seasonNumber, required this.episodes});
}

class Episode {
  final String name;
  final String url;
  final int episodeNumber;
  int watchedMilliseconds;
  int totalMilliseconds;

  Episode({
    required this.name,
    required this.url,
    required this.episodeNumber,
    this.watchedMilliseconds = 0,
    this.totalMilliseconds = 0,
  });
}
