import 'media_metadata.dart';

class SeriesItem {
  final int seriesId;
  final String name;
  final String? cover;
  final double rating;
  final String? categoryId;
  final String? categoryName;
  final String? plot;
  MediaMetadata? metadata;

  SeriesItem({
    required this.seriesId,
    required this.name,
    this.cover,
    this.rating = 0.0,
    this.categoryId,
    this.categoryName,
    this.plot,
    this.metadata,
  });

  String get id => seriesId.toString();
  String? get posterUrl => cover;

  factory SeriesItem.fromJson(Map<String, dynamic> json, {Map<String, String>? categoryMap}) {
    final catId = json['category_id']?.toString();
    return SeriesItem(
      seriesId: json['series_id'] is int ? json['series_id'] : int.parse(json['series_id'].toString()),
      name: json['name'] ?? 'Unknown',
      cover: json['cover'],
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      categoryId: catId,
      categoryName: categoryMap != null && catId != null ? categoryMap[catId] : null,
      plot: json['plot'],
    );
  }
}
