import 'dart:math';
import '../models/channel.dart';
import 'database_service.dart';
import 'preferences_service.dart';

/// Data model representing a personalized horizontal shelf on VortexTube
class VortexShelf {
  final String title;
  final String subtitle;
  final bool isCircular; // circular channel logos for Recent TV Channels
  final List<Channel> items;

  const VortexShelf({
    required this.title,
    required this.subtitle,
    required this.items,
    this.isCircular = false,
  });
}

/// Personalized recommendation & ranking engine for VortexTube.
///
/// RESTRICTION RULE:
/// Only content that belongs to a loved category OR is itself a loved item
/// may appear anywhere on this page.
class VortexTubeService {
  /// Base score formula for an eligible item:
  /// - Explicit favorite item: +50 points
  /// - Belonging to a loved category: +30 points
  /// - Play count frequency: min(25, playCount * 3) points
  /// - Watch recency: decaying up to +30 points if watched within 30 days
  /// - Continue watching / in-progress: +15 points if 0 < watchedMs < totalMs
  /// - Content rating (TMDB/metadata): rating * 1.5 points (up to 15 points)
  static double scoreItem({
    required Channel channel,
    required Set<String> lovedCategories,
    DateTime? now,
  }) {
    double score = 0.0;
    final currentTime = now ?? DateTime.now();

    // 1. Explicit item love / favorite (highest weight)
    if (channel.isFavorite) {
      score += 50.0;
    }

    // 2. Belongs to a loved category
    if (channel.group != null && lovedCategories.contains(channel.group!)) {
      score += 30.0;
    }

    // 3. Frequency of watches (playCount)
    score += min(25.0, channel.playCount * 3.0);

    // 4. Recency of last watch
    if (channel.lastPlayed != null) {
      final daysDiff = currentTime.difference(channel.lastPlayed!).inDays;
      if (daysDiff <= 0) {
        score += 30.0;
      } else if (daysDiff < 30) {
        score += max(0.0, 30.0 - daysDiff.toDouble());
      }
    }

    // 5. Completion rate / in-progress resume
    if (channel.watchedMilliseconds > 0 &&
        channel.totalMilliseconds > 0 &&
        channel.watchedMilliseconds < channel.totalMilliseconds) {
      score += 15.0;
    }

    // 6. Content rating
    score += min(15.0, channel.rating * 1.5);

    return score;
  }

  /// Builds the complete personalized feed for VortexTube.
  /// Returns empty list if user has zero loved categories and zero loved items.
  static Future<List<VortexShelf>> getPersonalizedFeed({String searchQuery = ''}) async {
    final lovedCategoriesList = await PreferencesService.getFavoriteCategories();
    final lovedCategories = lovedCategoriesList.toSet();

    final allChannels = await DatabaseService.getAllChannels();

    // Filter strictly to eligible content: loved category OR loved item
    var eligibleItems = allChannels.where((c) {
      final isItemLoved = c.isFavorite;
      final isCatLoved = c.group != null && lovedCategories.contains(c.group!);
      return isItemLoved || isCatLoved;
    }).toList();

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      eligibleItems = eligibleItems
          .where((c) => c.name.toLowerCase().contains(query) ||
              (c.group != null && c.group!.toLowerCase().contains(query)))
          .toList();
    }

    if (eligibleItems.isEmpty) {
      return [];
    }

    final shelves = <VortexShelf>[];
    final now = DateTime.now();

    // Section 1: Recent TV Channels (circular badges)
    // Eligible: Live channels that are loved or in loved live categories
    final liveChannels = eligibleItems
        .where((c) => c.contentType == ContentType.live)
        .toList();

    if (liveChannels.isNotEmpty) {
      final recentChannels = List<Channel>.from(liveChannels);
      // Sort primarily by lastPlayed desc, then playCount desc
      recentChannels.sort((a, b) {
        if (a.lastPlayed != null && b.lastPlayed != null) {
          return b.lastPlayed!.compareTo(a.lastPlayed!);
        } else if (a.lastPlayed != null) {
          return -1;
        } else if (b.lastPlayed != null) {
          return 1;
        }
        return b.playCount.compareTo(a.playCount);
      });

      shelves.add(VortexShelf(
        title: 'Recent TV Channels',
        subtitle: 'From your favorite live networks and categories',
        isCircular: true,
        items: recentChannels,
      ));

      // Section 1b: Loved Channels (circular badges)
      // Channels that are loved individually by user (isFavorite == true)
      final lovedIndividualChannels = liveChannels
          .where((c) => c.isFavorite)
          .toList();

      if (lovedIndividualChannels.isNotEmpty) {
        // Sort by personalization score / playCount / name
        lovedIndividualChannels.sort((a, b) {
          final scoreB = scoreItem(channel: b, lovedCategories: lovedCategories, now: now);
          final scoreA = scoreItem(channel: a, lovedCategories: lovedCategories, now: now);
          if (scoreB != scoreA) {
            return scoreB.compareTo(scoreA);
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        shelves.add(VortexShelf(
          title: 'Loved Channels',
          subtitle: 'Channels you individually favorited (${lovedIndividualChannels.length} channels)',
          isCircular: true,
          items: lovedIndividualChannels,
        ));
      }
    }

    // Section 2: Loved Movie Categories - Listing out all movies from actual favorite categories
    final movieItems = eligibleItems
        .where((c) => c.contentType == ContentType.movie)
        .toList();

    final movieCatNames = <String>{};
    for (final c in movieItems) {
      if (c.group != null && lovedCategories.contains(c.group!)) {
        movieCatNames.add(c.group!);
      }
    }

    final sortedMovieCats = movieCatNames.toList()..sort();
    for (final cat in sortedMovieCats) {
      final items = movieItems.where((c) => c.group == cat).toList();
      items.sort((a, b) => scoreItem(channel: b, lovedCategories: lovedCategories, now: now)
          .compareTo(scoreItem(channel: a, lovedCategories: lovedCategories, now: now)));

      shelves.add(VortexShelf(
        title: cat,
        subtitle: 'Movies (${items.length} titles)',
        items: items,
      ));
    }

    // Section 3: Loved Series Categories - Listing out all series from actual favorite categories
    final seriesItems = eligibleItems
        .where((c) => c.contentType == ContentType.series)
        .toList();

    final seriesCatNames = <String>{};
    for (final c in seriesItems) {
      if (c.group != null && lovedCategories.contains(c.group!)) {
        seriesCatNames.add(c.group!);
      }
    }

    final sortedSeriesCats = seriesCatNames.toList()..sort();
    for (final cat in sortedSeriesCats) {
      final items = seriesItems.where((c) => c.group == cat).toList();
      items.sort((a, b) => scoreItem(channel: b, lovedCategories: lovedCategories, now: now)
          .compareTo(scoreItem(channel: a, lovedCategories: lovedCategories, now: now)));

      shelves.add(VortexShelf(
        title: cat,
        subtitle: 'Series (${items.length} titles)',
        items: items,
      ));
    }

    return shelves;
  }
}
