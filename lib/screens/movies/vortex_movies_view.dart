import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../services/image_cache_service.dart';
import '../sidebar/vortex_nav_types.dart';

class VortexMoviesView extends StatelessWidget {
  final List<Channel> items;
  final Set<String> favoriteCategories;
  final VortexActiveFilter activeFilter;
  final VortexZone currentZone;
  final int focusedGridIndex;
  final ScrollController mainScrollController;
  final Map<int, GlobalKey> cardKeys;
  final void Function(Channel item, int globalIndex) onItemTap;

  const VortexMoviesView({
    super.key,
    required this.items,
    required this.favoriteCategories,
    required this.activeFilter,
    required this.currentZone,
    required this.focusedGridIndex,
    required this.mainScrollController,
    required this.cardKeys,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_outlined, color: Color(0xFF666666), size: 48),
              SizedBox(height: 16),
              Text(
                'No movies found in loved categories.',
                style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Use Settings to add favorite Movie categories.',
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<Channel>> grouped = {};

    if (activeFilter.type == VortexFilterType.all) {
      for (final favCat in favoriteCategories) {
        final catItems = items.where((c) => c.group == favCat).toList();
        if (catItems.isNotEmpty) {
          grouped[favCat] = catItems;
        }
      }
      for (final item in items) {
        final cat = item.group ?? 'Movies';
        if (!grouped.containsKey(cat)) {
          grouped.putIfAbsent(cat, () => []).add(item);
        }
      }
    } else {
      for (final item in items) {
        final cat = item.group ?? 'Movies';
        grouped.putIfAbsent(cat, () => []).add(item);
      }
    }

    int runningIndex = 0;

    return ListView(
      controller: mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 40),
      children: grouped.entries.map((entry) {
        final catName = entry.key;
        final catItems = entry.value;
        final startIndex = runningIndex;
        runningIndex += catItems.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 14),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF1E2025), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        catName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${catItems.length} Movies',
                        style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.60,
              ),
              itemCount: catItems.length,
              itemBuilder: (context, localIndex) {
                final globalIdx = startIndex + localIndex;
                final item = catItems[localIndex];
                final isFocused = currentZone == VortexZone.content && focusedGridIndex == globalIdx;
                final cardKey = cardKeys.putIfAbsent(globalIdx, () => GlobalKey());

                return GestureDetector(
                  key: cardKey,
                  onTap: () => onItemTap(item, globalIdx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1B1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFocused ? Colors.white : const Color(0xFF2B2D35).withValues(alpha: 0.4),
                        width: isFocused ? 2.5 : 1,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 18,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                            child: Container(
                              color: const Color(0xFF141518),
                              child: Center(
                                child: item.logo != null && item.logo!.isNotEmpty
                                    ? Image(
                                        image: ImageCacheService.getCachedImageProvider(item.logo!),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: const Color(0xFF181720),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFFFF0000),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.movie_outlined,
                                          color: Colors.white24,
                                          size: 38,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.movie_outlined,
                                        color: Colors.white24,
                                        size: 38,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  color: isFocused ? Colors.white : const Color(0xFFE2E2E2),
                                  fontSize: 12.5,
                                  fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.group ?? catName,
                                      style: const TextStyle(
                                        color: Color(0xFF9AA0A6),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.rating > 0) ...[
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      item.rating.toStringAsFixed(1),
                                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}
