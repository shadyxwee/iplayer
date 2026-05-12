import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/series.dart';
import 'series_detail_screen.dart';

class MobileSeriesDetailScreen extends StatelessWidget {
  final Channel series;
  final List<Channel> episodes;
  final String seriesTitle;

  const MobileSeriesDetailScreen({
    Key? key,
    required this.series,
    required this.episodes,
    required this.seriesTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a Series object from the channel and episodes
    final seriesObj = Series(
      id: series.tvgId?.toString(),
      playlistId: series.playlistId,
      name: seriesTitle,
      logo: series.logo,
      poster: series.logo,
      backdrop: series.logo,
      plot: series.description,
      rating: series.rating,
      seasons: [
        Season(
          seasonNumber: 1,
          episodes: episodes.map((e) => Episode(
            name: e.name,
            url: e.url,
            episodeNumber: 1,
          )).toList(),
        ),
      ],
    );

    return SeriesDetailScreen(series: seriesObj);
  }
}
