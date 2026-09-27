import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../services/m3u_parser.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/smooth_page_route.dart';
import 'movie_detail_screen.dart';
import 'video_player_screen.dart';

class ContentGridScreen extends StatefulWidget {
  final ContentType contentType;
  final String title;

  const ContentGridScreen({
    super.key,
    required this.contentType,
    required this.title,
  });

  @override
  State<ContentGridScreen> createState() => _ContentGridScreenState();
}

class _ContentGridScreenState extends State<ContentGridScreen> {
  List<Channel> _allContent = [];
  List<Channel> _filteredContent = [];
  List<Channel> _trendingContent = [];
  List<Channel> _recentContent = [];
  List<Channel> _favoriteContent = [];
  Map<String, Map<String, List<Channel>>> _hierarchy = {};
  String? _selectedParentCategory;
  String? _selectedSubCategory;
  String _searchQuery = '';
  String _sortBy = 'added';
  Channel? _featuredContent;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _backFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _backFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final allChannels = await DatabaseService.getAllChannels();
    final content = allChannels
        .where((c) => c.contentType == widget.contentType)
        .toList();

    final hierarchy = M3UParser.groupChannelsHierarchical(content);

    final trending = content.where((c) => c.rating >= 7.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final trendingList = trending.take(20).toList();

    final recent = content.where((c) => c.playCount > 0).toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final recentList = recent.take(20).toList();

    final favorites = content.where((c) => c.isFavorite).toList();

    Channel? featured;
    if (trendingList.isNotEmpty) {
      final withLogo = trendingList.where((c) => c.logo != null && c.logo!.isNotEmpty).toList();
      if (withLogo.isNotEmpty) {
        featured = withLogo[Random().nextInt(withLogo.length)];
      } else {
        featured = trendingList.first;
      }
    } else if (content.isNotEmpty) {
      final withLogo = content.where((c) => c.logo != null && c.logo!.isNotEmpty).toList();
      if (withLogo.isNotEmpty) {
        featured = withLogo[Random().nextInt(min(10, withLogo.length))];
      }
    }

    setState(() {
      _allContent = content;
      _filteredContent = content;
      _hierarchy = hierarchy;
      _trendingContent = trendingList;
      _recentContent = recentList;
      _favoriteContent = favorites;
      _featuredContent = featured;
      _isLoading = false;
    });
  }

  void _filterContent() {
    List<Channel> filtered = _allContent;

    if (_selectedParentCategory != null) {
      if (_selectedSubCategory != null && _selectedSubCategory != 'All') {
        filtered = filtered.where((c) {
          final g = (c.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          final sub = _selectedSubCategory!.toLowerCase();
          return g.contains(p) && g.contains(sub);
        }).toList();
      } else {
        filtered = filtered.where((c) {
          final g = (c.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          return g.startsWith(p) || g == p;
        }).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'added':
      default:
        break;
    }

    setState(() {
      _filteredContent = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111022),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111022),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF17152F),
              Color(0xFF0D0C1B),
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Left Sidebar - Categories
              _buildCategorySidebar(l10n),

              // Right side - Main Content Surface
              Expanded(
                child: Column(
                  children: [
                    // Top Bar with Sort Dropdown & Title Count
                    _buildTopHeaderBar(l10n),

                    // Main View
                    Expanded(
                      child: _selectedParentCategory == null && _searchQuery.isEmpty
                          ? _buildHomeView(l10n)
                          : _buildFilteredGridView(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySidebar(AppLocalizations l10n) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1A32),
        border: Border(right: BorderSide(color: Color(0xFF2C2A4C), width: 1)),
      ),
      child: Column(
        children: [
          // Logo & Back Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFocusIconButton(
                  focusNode: _backFocusNode,
                  icon: Icons.arrow_back,
                  tooltip: l10n.backButton,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Focus(
              focusNode: _searchFocusNode,
              child: Builder(builder: (context) {
                final isFocused = Focus.of(context).hasFocus;
                return Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1D34),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFocused ? const Color(0xFF6366F1) : const Color(0xFF2E2B52),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF8F92A9), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: l10n.search,
                            hintStyle: const TextStyle(color: Color(0xFF8F92A9), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _filterContent();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              itemCount: _hierarchy.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedParentCategory == null;
                  return _buildCategoryTile(l10n.all, isSelected, () {
                    setState(() {
                      _selectedParentCategory = null;
                      _selectedSubCategory = null;
                    });
                    _filterContent();
                  });
                }

                final parent = _hierarchy.keys.elementAt(index - 1);
                final subs = _hierarchy[parent]!;
                final isParentSelected = _selectedParentCategory == parent;

                return Column(
                  children: [
                    _buildCategoryTile(parent, isParentSelected, () {
                      setState(() {
                        if (_selectedParentCategory == parent && _selectedSubCategory == 'All') {
                          _selectedParentCategory = null;
                          _selectedSubCategory = null;
                        } else {
                          _selectedParentCategory = parent;
                          _selectedSubCategory = 'All';
                        }
                      });
                      _filterContent();
                    }, hasSub: subs.length > 1),

                    if (isParentSelected && subs.length > 1)
                      ...subs.keys.map((sub) {
                        final isSubSelected = _selectedSubCategory == sub;
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildCategoryTile(sub, isSubSelected, () {
                            setState(() {
                              _selectedSubCategory = sub;
                            });
                            _filterContent();
                          }, isSub: true),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String title, bool isSelected, VoidCallback onTap, {bool hasSub = false, bool isSub = false}) {
    bool isHovered = false;
    final focusNode = FocusNode();

    return StatefulBuilder(
      builder: (context, setState) {
        final isFocused = focusNode.hasFocus;
        final active = isSelected || isFocused || isHovered;

        return Focus(
          focusNode: focusNode,
          child: MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isSub ? 10 : 14,
                ),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF23223F) : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: active ? const Color(0xFF6366F1) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: active ? Colors.white : const Color(0xFF8F92A9),
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          fontSize: isSub ? 13 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasSub)
                      Icon(
                        isSelected ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 18,
                        color: active ? const Color(0xFF818CF8) : const Color(0xFF8F92A9),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeaderBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF16152A),
        border: Border(bottom: BorderSide(color: Color(0xFF2C2A4C), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1A32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2C2A4C)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                dropdownColor: const Color(0xFF1B1A32),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: [
                  DropdownMenuItem(value: 'added', child: Text(l10n.sortByAdded)),
                  DropdownMenuItem(value: 'name', child: Text(l10n.sortByName)),
                  DropdownMenuItem(value: 'rating', child: Text(l10n.sortByRating)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                    _filterContent();
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredContent.length} ${l10n.titlesCount}',
            style: const TextStyle(color: Color(0xFF8F92A9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView(AppLocalizations l10n) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_featuredContent != null)
          SliverToBoxAdapter(child: _buildHeroBanner(_featuredContent!, l10n)),

        if (_trendingContent.isNotEmpty) ...[
          _buildSectionHeader(l10n.trending, Icons.whatshot),
          _buildHorizontalCarousel(_trendingContent, isLarge: true, showRank: true),
        ],

        if (_recentContent.isNotEmpty) ...[
          _buildSectionHeader(l10n.continueWatching, Icons.history),
          _buildHorizontalCarousel(_recentContent, showProgress: true),
        ],

        if (_favoriteContent.isNotEmpty) ...[
          _buildSectionHeader(l10n.myList, Icons.favorite),
          _buildHorizontalCarousel(_favoriteContent),
        ],

        ..._buildCategoryCarousels(),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeroBanner(Channel content, AppLocalizations l10n) {
    return Container(
      height: 380,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (content.logo != null && content.logo!.isNotEmpty)
            Image.network(
              content.logo!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF111022)],
              ),
            ),
          ),
          Positioned(
            left: 32,
            bottom: 32,
            right: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.name,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _playContent(content),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.playButton),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showDetails(content),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2C2A4C)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.info_outline),
                      label: Text(l10n.moreInfo),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF818CF8), size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHorizontalCarousel(
    List<Channel> items, {
    bool isLarge = false,
    bool showProgress = false,
    bool showRank = false,
  }) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: isLarge ? 280 : 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildContentCard(items[index], width: isLarge ? 180 : 150, showProgress: showProgress);
          },
        ),
      ),
    );
  }

  Widget _buildContentCard(Channel content, {required double width, bool showProgress = false}) {
    bool isHovered = false;
    final itemFocusNode = FocusNode();

    return StatefulBuilder(
      builder: (context, setState) {
        final isFocused = itemFocusNode.hasFocus;
        final active = isFocused || isHovered;

        return Focus(
          focusNode: itemFocusNode,
          child: MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            cursor: SystemMouseCursors.click,
            child: Container(
              width: width,
              margin: const EdgeInsets.only(right: 14),
              child: InkWell(
                onTap: () => _showDetails(content),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: active ? Matrix4.translationValues(0.0, -3.0, 0.0) : Matrix4.identity(),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1A32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? const Color(0xFF6366F1) : const Color(0xFF2C2A4C),
                      width: active ? 2 : 1,
                    ),
                    boxShadow: active
                        ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 16)]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: content.logo != null && content.logo!.isNotEmpty
                              ? Image.network(
                                  content.logo!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie, color: Color(0xFF8F92A9), size: 40)),
                                )
                              : const Center(child: Icon(Icons.movie, color: Color(0xFF8F92A9), size: 40)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          content.name,
                          style: TextStyle(
                            color: active ? Colors.white : const Color(0xFFCBD5E1),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCategoryCarousels() {
    final List<Widget> sections = [];
    final parents = _hierarchy.keys.toList()..sort();

    for (final parent in parents.take(6)) {
      final subs = _hierarchy[parent]!;
      List<Channel> items = [];
      subs.values.forEach((list) => items.addAll(list));

      if (items.isNotEmpty) {
        sections.add(_buildSectionHeader(parent, Icons.category));
        sections.add(_buildHorizontalCarousel(items.take(15).toList()));
      }
    }

    return sections;
  }

  Widget _buildFilteredGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredContent.length,
      itemBuilder: (context, index) {
        return _buildContentCard(_filteredContent[index], width: 160);
      },
    );
  }

  Widget _buildFocusIconButton({
    required FocusNode focusNode,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    bool isHovered = false;

    return Focus(
      focusNode: focusNode,
      child: StatefulBuilder(
        builder: (context, setState) {
          final isFocused = Focus.of(context).hasFocus;
          final active = isFocused || isHovered;

          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: tooltip,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF282645) : const Color(0xFF1E1D34),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? const Color(0xFF6366F1) : const Color(0xFF2E2B52),
                    ),
                  ),
                  child: Icon(icon, color: active ? Colors.white : const Color(0xFF8F92A9), size: 18),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _playContent(Channel content) async {
    await Navigator.push(
      context,
      SmoothPageRoute(child: VideoPlayerScreen(channel: content)),
    );
    _loadContent();
  }

  void _showDetails(Channel content) async {
    await Navigator.push(
      context,
      SmoothPageRoute(child: MovieDetailScreen(movie: content)),
    );
    _loadContent();
  }
}
