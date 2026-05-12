class MediaMetadata {
  final String? title;
  final String? plot;
  final String? posterUrl;
  final String? backdropUrl;
  final double? rating;
  final String? releaseDate;
  final String? genre;
  final String? cast;
  final String? director;
  final String? trailer;
  final String? tmdbId;
  final Map<String, dynamic>? extraData;

  MediaMetadata({
    this.title,
    this.plot,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.releaseDate,
    this.genre,
    this.cast,
    this.director,
    this.trailer,
    this.tmdbId,
    this.extraData,
  });

  MediaMetadata copyWith({
    String? title,
    String? plot,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    String? releaseDate,
    String? genre,
    String? cast,
    String? director,
    String? trailer,
    String? tmdbId,
    Map<String, dynamic>? extraData,
  }) {
    return MediaMetadata(
      title: title ?? this.title,
      plot: plot ?? this.plot,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      releaseDate: releaseDate ?? this.releaseDate,
      genre: genre ?? this.genre,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      trailer: trailer ?? this.trailer,
      tmdbId: tmdbId ?? this.tmdbId,
      extraData: extraData ?? this.extraData,
    );
  }

  factory MediaMetadata.merge(MediaMetadata primary, MediaMetadata fallback) {
    bool isEmpty(String? s) => s == null || s.trim().isEmpty || s.toLowerCase() == 'n/a' || s.toLowerCase() == 'none';

    return MediaMetadata(
      title: !isEmpty(primary.title) ? primary.title : fallback.title,
      plot: !isEmpty(primary.plot) ? primary.plot : fallback.plot,
      posterUrl: !isEmpty(primary.posterUrl) ? primary.posterUrl : fallback.posterUrl,
      backdropUrl: !isEmpty(primary.backdropUrl) ? primary.backdropUrl : fallback.backdropUrl,
      rating: (primary.rating != null && primary.rating! > 0) ? primary.rating : fallback.rating,
      releaseDate: !isEmpty(primary.releaseDate) ? primary.releaseDate : fallback.releaseDate,
      genre: !isEmpty(primary.genre) ? primary.genre : fallback.genre,
      cast: !isEmpty(primary.cast) ? primary.cast : fallback.cast,
      director: !isEmpty(primary.director) ? primary.director : fallback.director,
      trailer: !isEmpty(primary.trailer) ? primary.trailer : fallback.trailer,
      tmdbId: !isEmpty(primary.tmdbId) ? primary.tmdbId : fallback.tmdbId,
      extraData: primary.extraData ?? fallback.extraData,
    );
  }

  static double? _parseRating(dynamic value) {
    if (value == null) return null;
    final r = double.tryParse(value.toString());
    if (r == null || r <= 0) return null;
    return r > 10 ? r / 10 : r; // Some providers return 0-100 scales
  }

  factory MediaMetadata.fromXtreamVodInfo(Map<String, dynamic> json) {
    final info = json['info'] ?? {};
    final movieData = json['movie_data'] ?? {};
    
    return MediaMetadata(
      title: (info['name'] ?? movieData['name'])?.toString(),
      plot: info['plot']?.toString(),
      posterUrl: info['movie_image']?.toString(),
      backdropUrl: (info['backdrop_path'] is List && info['backdrop_path'].isNotEmpty) 
          ? info['backdrop_path'][0]?.toString() 
          : info['backdrop_path']?.toString(),
      rating: _parseRating(info['rating']),
      releaseDate: info['releasedate']?.toString(),
      genre: info['genre']?.toString(),
      cast: info['cast']?.toString(),
      director: info['director']?.toString(),
      trailer: info['youtube_trailer']?.toString(),
      tmdbId: info['tmdb_id']?.toString(),
      extraData: info,
    );
  }

  factory MediaMetadata.fromXtreamSeriesInfo(Map<String, dynamic> json) {
    final info = json['info'] ?? {};
    
    return MediaMetadata(
      title: info['name']?.toString(),
      plot: info['plot']?.toString(),
      posterUrl: info['cover']?.toString(),
      backdropUrl: (info['backdrop_path'] is List && info['backdrop_path'].isNotEmpty) 
          ? info['backdrop_path'][0]?.toString() 
          : info['backdrop_path']?.toString(),
      rating: _parseRating(info['rating']),
      releaseDate: info['releaseDate']?.toString(),
      genre: info['genre']?.toString(),
      cast: info['cast']?.toString(),
      director: info['director']?.toString(),
      trailer: info['youtube_trailer']?.toString(),
      tmdbId: info['tmdb_id']?.toString(),
      extraData: info,
    );
  }
}
