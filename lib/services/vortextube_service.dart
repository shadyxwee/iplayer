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
  static Future<List<VortexShelf>> getPersonalizedFeed() async {
    final lovedCategoriesList = await PreferencesService.getFavoriteCategories();
    final lovedCategories = lovedCategoriesList.toSet();

    final allChannels = await DatabaseService.getAllChannels();

    // Filter strictly to eligible content: loved category OR loved item
    final eligibleItems = allChannels.where((c) {
      final isItemLoved = c.isFavorite;
      final isCatLoved = c.group != null && lovedCategories.contains(c.group!);
      return isItemLoved || isCatLoved;
    }).toList();

    if (eligibleItems.isEmpty) {
      return [];
    }

    final shelves = <VortexShelf>[];
    final now = DateTime.now();

    // Shelf 1: Recent TV Channels (circular badges)
    // Eligible: Live channels that are loved or in loved live categories
    final liveChannels = eligibleItems
        .where((c) => c.contentType == ContentType.live)
        .toList();

    if (liveChannels.isNotEmpty) {
      // Sort primarily by lastPlayed desc, then playCount desc
      liveChannels.sort((a, b) {
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
        items: liveChannels.take(12).toList(),
      ));
    }

    // Non-live eligible items (strictly Movies/VOD and Series for video card shelves)
    final nonLiveItems = eligibleItems
        .where((c) => c.contentType != ContentType.live)
        .toList();

    // Shelf 2: Continue Watching (loved movies/series with progress)
    final inProgressItems = nonLiveItems.where((c) {
      return c.watchedMilliseconds > 0 &&
          (c.totalMilliseconds == 0 || c.watchedMilliseconds < c.totalMilliseconds);
    }).toList();

    if (inProgressItems.isNotEmpty) {
      inProgressItems.sort((a, b) {
        if (a.lastPlayed != null && b.lastPlayed != null) {
          return b.lastPlayed!.compareTo(a.lastPlayed!);
        }
        return b.watchedMilliseconds.compareTo(a.watchedMilliseconds);
      });

      shelves.add(VortexShelf(
        title: 'Continue Watching',
        subtitle: 'Pick up where you left off',
        items: inProgressItems.take(12).toList(),
      ));
    }

    // Shelf 3: Recommended for You (highest scored movies/series only)
    if (nonLiveItems.isNotEmpty) {
      final scoredItems = nonLiveItems.map((item) {
        return MapEntry(item, scoreItem(channel: item, lovedCategories: lovedCategories, now: now));
      }).toList();

      scoredItems.sort((a, b) => b.value.compareTo(a.value));

      final topRecommended = scoredItems.map((e) => e.key).take(12).toList();
      if (topRecommended.isNotEmpty) {
        shelves.add(VortexShelf(
          title: 'Recommended for You',
          subtitle: 'Curated by VortexTube ranking based on your loved preferences',
          items: topRecommended,
        ));
      }
    }

    // Shelves 4+: Dedicated sections for the user's Actual Loved Categories
    // Group loved categories into Movies and Series categories and list out all their contents
    for (final lovedCat in lovedCategories) {
      final catItems = nonLiveItems
          .where((c) => c.group == lovedCat)
          .toList();

      if (catItems.isNotEmpty) {
        // Sort items in this loved category by score
        catItems.sort((a, b) => scoreItem(channel: b, lovedCategories: lovedCategories, now: now)
            .compareTo(scoreItem(channel: a, lovedCategories: lovedCategories, now: now)));

        final isSeriesCategory = catItems.any((c) => c.contentType == ContentType.series);
        final typeLabel = isSeriesCategory ? 'Series' : 'Movies';

        shelves.add(VortexShelf(
          title: '$lovedCat ($typeLabel)',
          subtitle: 'All loved titles from $lovedCat',
          items: catItems,
        ));
      }
    }

    return shelves;
  }
}
