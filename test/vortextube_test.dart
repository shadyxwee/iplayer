import 'package:flutter_test/flutter_test.dart';
import 'package:riptv/models/channel.dart';
import 'package:riptv/services/vortextube_service.dart';

void main() {
  group('VortexTube Personalization Engine Tests', () {
    test('scoreItem correctly prioritizes explicit favorites and loved categories', () {
      final now = DateTime(2025, 1, 1, 12, 0);

      final lovedItem = Channel()
        ..name = 'Loved Channel'
        ..group = 'Sports'
        ..isFavorite = true
        ..playCount = 10
        ..rating = 8.0;

      final lovedCategoryItem = Channel()
        ..name = 'Normal Channel'
        ..group = 'Sports'
        ..isFavorite = false
        ..playCount = 2
        ..rating = 6.0;

      final unlovedItem = Channel()
        ..name = 'Unloved Channel'
        ..group = 'News'
        ..isFavorite = false
        ..playCount = 0
        ..rating = 5.0;

      final lovedCategories = {'Sports'};

      final score1 = VortexTubeService.scoreItem(
        channel: lovedItem,
        lovedCategories: lovedCategories,
        now: now,
      );

      final score2 = VortexTubeService.scoreItem(
        channel: lovedCategoryItem,
        lovedCategories: lovedCategories,
        now: now,
      );

      final score3 = VortexTubeService.scoreItem(
        channel: unlovedItem,
        lovedCategories: lovedCategories,
        now: now,
      );

      // Loved item + loved category must score significantly higher than loved category only
      expect(score1 > score2, isTrue);
      // Loved category item must score higher than unloved item
      expect(score2 > score3, isTrue);
      // Loved item has 50 (favorite) + 30 (category) + 25 (playCount capped) + 12 (rating*1.5) = 117
      expect(score1, greaterThan(100.0));
    });

    test('scoreItem factors in in-progress watch progress and recency decay', () {
      final now = DateTime(2025, 1, 15, 12, 0);

      final recentInProgress = Channel()
        ..name = 'In Progress Movie'
        ..group = 'Action'
        ..isFavorite = true
        ..lastPlayed = DateTime(2025, 1, 15, 10, 0) // today
        ..watchedMilliseconds = 30000
        ..totalMilliseconds = 60000;

      final olderComplete = Channel()
        ..name = 'Older Complete'
        ..group = 'Action'
        ..isFavorite = true
        ..lastPlayed = DateTime(2024, 12, 1, 10, 0) // > 30 days ago
        ..watchedMilliseconds = 60000
        ..totalMilliseconds = 60000;

      final lovedCategories = {'Action'};

      final scoreRecent = VortexTubeService.scoreItem(
        channel: recentInProgress,
        lovedCategories: lovedCategories,
        now: now,
      );

      final scoreOlder = VortexTubeService.scoreItem(
        channel: olderComplete,
        lovedCategories: lovedCategories,
        now: now,
      );

      expect(scoreRecent > scoreOlder, isTrue);
    });
  });
}
