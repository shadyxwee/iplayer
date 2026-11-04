import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../services/image_cache_service.dart';
import '../../services/vortextube_service.dart';
import '../sidebar/vortex_nav_types.dart';

class VortexHomeView extends StatelessWidget {
  final List<VortexShelf> shelves;
  final ScrollController mainScrollController;
  final Map<int, ScrollController> shelfScrollControllers;
  final VortexZone currentZone;
  final int focusedShelfIndex;
  final int focusedItemIndex;
  final void Function(Channel item, int shelfIndex, int itemIndex) onItemTap;
  final VoidCallback onAddCategoriesTap;

  const VortexHomeView({
    super.key,
    required this.shelves,
    required this.mainScrollController,
    required this.shelfScrollControllers,
    required this.currentZone,
    required this.focusedShelfIndex,
    required this.focusedItemIndex,
    required this.onItemTap,
    required this.onAddCategoriesTap,
  });

  @override
  Widget build(BuildContext context) {
    if (shelves.isEmpty) {
      return _buildEmptyState();
    }
    return _buildShelvesList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF0000), size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Personalized VortexTube Feed',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'VortexTube only showcases content from your favorite categories and loved items.\nClick "Add More" to favorite categories from your playlist.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddCategoriesTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('Add Categories Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelvesList() {
    return ListView.builder(
      controller: mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 40),
      itemCount: shelves.length,
      itemBuilder: (context, shelfIndex) {
        final shelf = shelves[shelfIndex];
        return _buildShelfSection(shelf, shelfIndex);
      },
    );
  }

  Widget _buildShelfSection(VortexShelf shelf, int shelfIndex) {
    final controller = shelfScrollControllers.putIfAbsent(
      shelfIndex,
      () => ScrollController(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                shelf.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                shelf.subtitle,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: shelf.isCircular ? 130 : 310,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: shelf.items.length,
              itemBuilder: (context, itemIndex) {
                final item = shelf.items[itemIndex];
                final isFocused = currentZone == VortexZone.content &&
                    focusedShelfIndex == shelfIndex &&
                    focusedItemIndex == itemIndex;

                return shelf.isCircular
                    ? _buildCircularCard(item, isFocused, shelfIndex, itemIndex)
                    : _buildPosterCard(item, isFocused, shelfIndex, itemIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularCard(Channel item, bool isFocused, int shelfIndex, int itemIndex) {
    return GestureDetector(
      onTap: () => onItemTap(item, shelfIndex, itemIndex),
      child: Container(
        width: 95,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isFocused ? 76 : 70,
              height: isFocused ? 76 : 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1F1F1F),
                border: Border.all(
                  color: isFocused ? Colors.white : const Color(0xFF333333),
                  width: isFocused ? 3 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: item.logo != null && item.logo!.isNotEmpty
                    ? Image.network(
                        item.logo!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white70, size: 26),
                      )
                    : const Icon(Icons.tv, color: Colors.white70, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: TextStyle(
                color: isFocused ? Colors.white : const Color(0xFFAAAAAA),
                fontSize: 12,
                fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterCard(Channel item, bool isFocused, int shelfIndex, int itemIndex) {
    return GestureDetector(
      onTap: () => onItemTap(item, shelfIndex, itemIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 175,
        margin: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFocused ? Colors.white : const Color(0xFF282828),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Container(
                  color: const Color(0xFF181818),
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
                                color: const Color(0xFF181818),
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
                            errorBuilder: (_, __, ___) => const Icon(Icons.movie_outlined, color: Colors.white24, size: 40),
                          )
                        : const Icon(Icons.movie_outlined, color: Colors.white24, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: isFocused ? Colors.white : const Color(0xFFE0E0E0),
                      fontSize: 13,
                      fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.group ?? 'Loved',
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.rating > 0) ...[
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
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
  }
}
