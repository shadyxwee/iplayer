import 'media_metadata.dart';

class VodItem {
  final int streamId;
  final String name;
  final String? streamIcon;
  final double rating;
  final String? containerExtension;
  final String? categoryId;
  final String? categoryName;
  final String? plot;
  final String baseUrl;
  final String username;
  final String password;
  MediaMetadata? metadata;

  VodItem({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.rating = 0.0,
    this.containerExtension,
    this.categoryId,
    this.categoryName,
    this.plot,
    required this.baseUrl,
    required this.username,
    required this.password,
    this.metadata,
  });

  String get streamUrl => '$baseUrl/movie/$username/$password/$streamId.${containerExtension ?? "mp4"}';
  String? get posterUrl => streamIcon;

  factory VodItem.fromJson(Map<String, dynamic> json, String baseUrl, String username, String password, {Map<String, String>? categoryMap}) {
    final catId = json['category_id']?.toString();
    return VodItem(
      streamId: json['stream_id'] is int ? json['stream_id'] : int.parse(json['stream_id'].toString()),
      name: json['name'] ?? 'Unknown',
      streamIcon: json['stream_icon'],
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      containerExtension: json['container_extension'],
      categoryId: catId,
      categoryName: categoryMap != null && catId != null ? categoryMap[catId] : null,
      plot: json['plot'],
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
  }
}
