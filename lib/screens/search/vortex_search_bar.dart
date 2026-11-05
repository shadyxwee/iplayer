import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sidebar/vortex_nav_types.dart';

class VortexSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final VortexZone currentZone;
  final VortexNavTarget activeNav;
  final VortexSortOption sortOption;
  final bool isSidebarExpanded;
  final VoidCallback onToggleSidebar;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onCycleSort;
  final VoidCallback? onLeftArrowPressed;
  final VoidCallback? onRefreshPressed;

  const VortexSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.currentZone,
    required this.activeNav,
    required this.sortOption,
    required this.isSidebarExpanded,
    required this.onToggleSidebar,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onCycleSort,
    this.onLeftArrowPressed,
    this.onRefreshPressed,
  });

  String _getSortLabel() {
    switch (sortOption) {
      case VortexSortOption.recommended:
        return 'Recommended';
      case VortexSortOption.nameAsc:
        return 'Name (A - Z)';
      case VortexSortOption.nameDesc:
        return 'Name (Z - A)';
      case VortexSortOption.releaseDate:
        return 'Release Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearchFocused = currentZone == VortexZone.searchBar;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
      ),
      child: Row(
        children: [
          // Collapse / Expand Toggle Button in header
          Tooltip(
            message: isSidebarExpanded ? 'Collapse Sidebar' : 'Expand Sidebar',
            child: InkWell(
              onTap: onToggleSidebar,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 280),
                  turns: isSidebarExpanded ? 0 : 0.5,
                  child: const Icon(
                    Icons.menu_open_rounded,
                    color: Color(0xFFA3A3A3),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Search Capsule
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSearchFocused ? Colors.white : Colors.transparent,
                width: isSearchFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded, color: Color(0xFFAAAAAA), size: 18),
                ),
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                          onLeftArrowPressed != null) {
                        onLeftArrowPressed!();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search VortexTube...',
                        hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: onSearchChanged,
                      onSubmitted: onSearchSubmitted,
                    ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: onClearSearch,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.clear, color: Color(0xFF888888), size: 16),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Refresh Icon Button next to search capsule
          Tooltip(
            message: 'Refresh Feed & Clear Cache',
            child: InkWell(
              onTap: onRefreshPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF383838)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFFDDDDDD),
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Sorting Button (Movies / Series) directly in the same row
          if (activeNav == VortexNavTarget.movies || activeNav == VortexNavTarget.series)
            InkWell(
              onTap: onCycleSort,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF202025),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2E2E35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _getSortLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
