import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../sidebar/vortex_nav_types.dart';

class VortexLiveView extends StatelessWidget {
  final List<Channel> items;
  final Set<String> favoriteCategories;
  final VortexActiveFilter activeFilter;
  final VortexZone currentZone;
  final int focusedGridIndex;
  final ScrollController mainScrollController;
  final Map<int, GlobalKey> cardKeys;
  final void Function(Channel item, int globalIndex) onItemTap;

  const VortexLiveView({
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
              Icon(Icons.live_tv_rounded, color: Color(0xFF666666), size: 48),
              SizedBox(height: 16),
              Text(
                'No channels found in loved categories.',
                style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Use Settings to add favorite Live TV categories.',
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
        final catChannels = items.where((c) => c.group == favCat).toList();
        if (catChannels.isNotEmpty) {
          grouped[favCat] = catChannels;
        }
      }
      for (final channel in items) {
        final cat = channel.group ?? 'Other Channels';
        if (!grouped.containsKey(cat)) {
          grouped.putIfAbsent(cat, () => []).add(channel);
        }
      }
    } else {
      for (final channel in items) {
        final cat = channel.group ?? 'Other Channels';
        grouped.putIfAbsent(cat, () => []).add(channel);
      }
    }

    int runningIndex = 0;

    return ListView(
      controller: mainScrollController,
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 40),
      children: grouped.entries.map((entry) {
        final catName = entry.key;
        final channels = entry.value;
        final startIndex = runningIndex;
        runningIndex += channels.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 14),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF1A1A1F), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        catName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '${channels.length} Channels',
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w500),
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
                crossAxisCount: 10,
                crossAxisSpacing: 14,
                mainAxisSpacing: 22,
                childAspectRatio: 0.8,
              ),
              itemCount: channels.length,
              itemBuilder: (context, localIndex) {
                final globalIdx = startIndex + localIndex;
                final item = channels[localIndex];
                final isFocused = currentZone == VortexZone.content && focusedGridIndex == globalIdx;
                final cardKey = cardKeys.putIfAbsent(globalIdx, () => GlobalKey());

                return GestureDetector(
                  key: cardKey,
                  onTap: () => onItemTap(item, globalIdx),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: isFocused ? 74 : 66,
                        height: isFocused ? 74 : 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1E24),
                          border: Border.all(
                            color: isFocused ? Colors.white : const Color(0xFF2D2D35),
                            width: isFocused ? 2.5 : 1,
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
                        padding: const EdgeInsets.all(9),
                        child: ClipOval(
                          child: item.logo != null && item.logo!.isNotEmpty
                              ? Image.network(
                                  item.logo!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white70, size: 24),
                                )
                              : const Icon(Icons.tv, color: Colors.white70, size: 24),
                        ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 86,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: isFocused ? Colors.white : const Color(0xFF8E8E93),
                            fontSize: 10,
                            fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
