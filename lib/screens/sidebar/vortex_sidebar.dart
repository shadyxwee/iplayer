import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import 'vortex_nav_types.dart';

class VortexSidebar extends StatelessWidget {
  final bool isSidebarExpanded;
  final bool isSidebarHovered;
  final VortexNavTarget activeNav;
  final VortexZone currentZone;
  final int focusedNavIndex;
  final Playlist? activePlaylist;
  final List<Map<String, dynamic>> navItems;
  final VoidCallback onMouseEnter;
  final VoidCallback onMouseExit;
  final ValueChanged<VortexNavTarget> onSelectNavTarget;
  final void Function(int navIndex, VortexNavTarget target) onSidebarTap;

  const VortexSidebar({
    super.key,
    required this.isSidebarExpanded,
    required this.isSidebarHovered,
    required this.activeNav,
    required this.currentZone,
    required this.focusedNavIndex,
    required this.activePlaylist,
    required this.navItems,
    required this.onMouseEnter,
    required this.onMouseExit,
    required this.onSelectNavTarget,
    required this.onSidebarTap,
  });

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = isSidebarExpanded ? 290.0 : 80.0;
    final double horizontalPadding = isSidebarExpanded ? 14.0 : 10.0;

    return MouseRegion(
      onEnter: (_) => onMouseEnter(),
      onExit: (_) => onMouseExit(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        width: sidebarWidth,
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(right: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
        ),
        child: Column(
          children: [
            // Brand Header & Toggle
            Container(
              padding: EdgeInsets.only(
                top: 24,
                bottom: 16,
                left: isSidebarExpanded ? 16 : 8,
                right: isSidebarExpanded ? 12 : 8,
              ),
              child: Row(
                mainAxisAlignment: isSidebarExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                children: [
                  // Logo + VortexTube title
                  Expanded(
                    child: Row(
                      mainAxisAlignment: isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        // YouTube-style Red Play Logo: 40x28, rounded-[10px]
                        Container(
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        // Brand Title animated
                        ClipRect(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                            width: isSidebarExpanded ? 140 : 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isSidebarExpanded ? 1.0 : 0.0,
                              child: Transform.translate(
                                offset: Offset(isSidebarExpanded ? 0 : -10, 0),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    'VortexTube',
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation List (Vertically centered between Header and Profile)
            Expanded(
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  children: [
                    _buildSidebarButton(VortexNavTarget.search, Icons.search_rounded, 'Search', 0),
                    _buildSidebarButton(VortexNavTarget.home, Icons.home_rounded, 'Home', 1),
                    _buildSidebarButton(VortexNavTarget.movies, Icons.movie_outlined, 'Movies', 2),
                    _buildSidebarButton(VortexNavTarget.liveTv, Icons.live_tv_rounded, 'Live TV', 3),
                    _buildSidebarButton(VortexNavTarget.series, Icons.video_collection_outlined, 'Series', 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Divider(color: Color(0xFF202020), height: 1),
                    ),
                    _buildSidebarButton(VortexNavTarget.settings, Icons.settings_outlined, 'Settings', 5),
                  ],
                ),
              ),
            ),

            // User Profile Box at bottom
            Container(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF202020), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF888888), width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Color(0xFF888888), size: 14),
                    ),
                  ),
                  ClipRect(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      width: isSidebarExpanded ? 180 : 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSidebarExpanded ? 1.0 : 0.0,
                        child: Transform.translate(
                          offset: Offset(isSidebarExpanded ? 0 : -10, 0),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              activePlaylist?.macAddress != null && activePlaylist!.macAddress!.isNotEmpty
                                  ? (activePlaylist?.name != null && activePlaylist!.name.isNotEmpty
                                      ? '${activePlaylist!.name} (${activePlaylist!.macAddress})'
                                      : activePlaylist!.macAddress!)
                                  : (activePlaylist?.name ?? 'Profile'),
                              style: const TextStyle(
                                color: Color(0xFFA3A3A3),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarButton(VortexNavTarget target, IconData icon, String label, int navIndex) {
    final isFocused = currentZone == VortexZone.sidebar && focusedNavIndex == navIndex;
    final isActive = activeNav == target;
    final isHighlighted = isFocused || (isActive && currentZone != VortexZone.sidebar);

    Color backgroundColor;
    Color iconColor;
    Color textColor;
    FontWeight fontWeight;

    if (isHighlighted) {
      backgroundColor = const Color(0xFFEEEEEE);
      iconColor = Colors.black;
      textColor = Colors.black;
      fontWeight = FontWeight.bold;
    } else {
      backgroundColor = Colors.transparent;
      iconColor = const Color(0xFFA3A3A3);
      textColor = const Color(0xFFA3A3A3);
      fontWeight = FontWeight.w500;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: Tooltip(
        message: !isSidebarExpanded ? label : '',
        child: InkWell(
          onTap: () => onSidebarTap(navIndex, target),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: isSidebarExpanded ? 16 : 0,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: null,
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                ),
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    width: isSidebarExpanded ? 180 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSidebarExpanded ? 1.0 : 0.0,
                      child: Transform.translate(
                        offset: Offset(isSidebarExpanded ? 0 : -10, 0),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: fontWeight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
