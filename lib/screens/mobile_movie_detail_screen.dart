import 'package:flutter/material.dart';
import '../models/channel.dart';
import 'movie_detail_screen.dart';

class MobileMovieDetailScreen extends StatelessWidget {
  final Channel movie;
  const MobileMovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Reuse the refined MovieDetailScreen as it's designed to be responsive
    return MovieDetailScreen(movie: movie);
  }
}
