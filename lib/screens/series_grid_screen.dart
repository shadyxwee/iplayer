import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/channel.dart';
import '../models/series.dart';
import '../services/database_service.dart';
import '../services/series_parser.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/smooth_page_route.dart';
import 'series_detail_screen.dart';

class SeriesGridScreen extends StatefulWidget {
  const SeriesGridScreen({super.key});

  @override
  State<SeriesGridScreen> createState() => _SeriesGridScreenState();
}

class _SeriesGridScreenState extends State<SeriesGridScreen> {
  Map<String, Series> _allSeries = {};
  List<Series> _filteredSeries = [];
  List<Series> _trendingSeries = [];
  List<Series> _recentSeries = [];
  Map<String, Map<String, List<Series>>> _hierarchy = {};
  String? _selectedParentCategory;
  String? _selectedSubCategory;
  String _searchQuery = '';
  String _sortBy = 'added';
  Series? _featuredSeries;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _backFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _backFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSeries() async {
    final allChannels = await DatabaseService.getAllChannels();
    final seriesChannels = allChannels
        .where((c) => c.contentType == ContentType.series)
        .toList();

    final Map<String, Series> seriesMap = SeriesParser.groupIntoSeries(seriesChannels);

    final hierarchy = <String, Map<String, List<Series>>>{};

    seriesMap.values.forEach((series) {
      final fullGroup = series.group ?? "Uncategorized";

      String parent = fullGroup;
      String sub = 'Other';

      final separators = ['|', ' - ', ':', ' / '];
      for (final sep in separators) {
        if (fullGroup.contains(sep)) {
          final parts = fullGroup.split(sep);
          parent = parts[0].trim();
          sub = parts.sublist(1).join(sep).trim();
          break;
        }
      }

      hierarchy.putIfAbsent(parent, () => {});
      hierarchy[parent]!.putIfAbsent(sub, () => []);
      hierarchy[parent]![sub]!.add(series);
    });

    final trending = seriesMap.values.where((s) => (s.rating ?? 0) >= 7.0).toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    final trendingList = trending.take(20).toList();

    final recent = seriesMap.values.where((s) {
      return s.seasons.any((season) =>
        season.episodes.any((ep) => ep.watchedMilliseconds > 0));
    }).toList();

    Series? featured;
    if (trendingList.isNotEmpty) {
      final withPoster = trendingList.where((s) => s.poster != null && s.poster!.isNotEmpty).toList();
      if (withPoster.isNotEmpty) {
        featured = withPoster[Random().nextInt(withPoster.length)];
      } else {
        featured = trendingList.first;
      }
    } else if (seriesMap.isNotEmpty) {
      final withPoster = seriesMap.values.where((s) => s.poster != null && s.poster!.isNotEmpty).toList();
      if (withPoster.isNotEmpty) {
        featured = withPoster.toList()[Random().nextInt(min(10, withPoster.length))];
      }
    }

    setState(() {
      _allSeries = seriesMap;
      _filteredSeries = seriesMap.values.toList();
      _hierarchy = hierarchy;
      _trendingSeries = trendingList;
      _recentSeries = recent.take(20).toList();
      _featuredSeries = featured;
      _isLoading = false;
    });
  }

  void _filterSeries() {
    List<Series> filtered;

    if (_selectedParentCategory != null) {
      if (_selectedSubCategory != null && _selectedSubCategory != 'All') {
        filtered = _allSeries.values.where((s) {
          final g = (s.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          final sub = _selectedSubCategory!.toLowerCase();
          return g.contains(p) && g.contains(sub);
        }).toList();
      } else {
        filtered = _allSeries.values.where((s) {
          final g = (s.group ?? '').toLowerCase();
          final p = _selectedParentCategory!.toLowerCase();
          return g.startsWith(p) || g == p;
        }).toList();
      }
    } else {
      filtered = _allSeries.values.toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'added':
      default:
        break;
    }

    setState(() {
      _filteredSeries = filtered;
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

              // Right side - Content Surface
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeaderBar(l10n),
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
                    'SERIES',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.series,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

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
                            _filterSeries();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

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
                    _filterSeries();
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
                      _filterSeries();
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
                            _filterSeries();
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
                    _filterSeries();
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredSeries.length} ${l10n.seriesLabel}',
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
        if (_featuredSeries != null)
          SliverToBoxAdapter(child: _buildHeroBanner(_featuredSeries!, l10n)),

        if (_trendingSeries.isNotEmpty) ...[
          _buildSectionHeader(l10n.trending, Icons.whatshot),
          _buildHorizontalCarousel(_trendingSeries, isLarge: true),
        ],

        if (_recentSeries.isNotEmpty) ...[
          _buildSectionHeader(l10n.continueWatching, Icons.history),
          _buildHorizontalCarousel(_recentSeries),
        ],

        ..._buildCategoryCarousels(),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeroBanner(Series series, AppLocalizations l10n) {
    return Container(
      height: 380,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (series.poster != null && series.poster!.isNotEmpty)
            Image.network(
              series.poster!,
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
                  series.name,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showDetails(series),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: Text(l10n.moreInfo),
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

  SliverToBoxAdapter _buildHorizontalCarousel(List<Series> items, {bool isLarge = false}) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: isLarge ? 280 : 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildSeriesCard(items[index], width: isLarge ? 180 : 150);
          },
        ),
      ),
    );
  }

  Widget _buildSeriesCard(Series series, {required double width}) {
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
                onTap: () => _showDetails(series),
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
                          child: series.poster != null && series.poster!.isNotEmpty
                              ? Image.network(
                                  series.poster!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.tv, color: Color(0xFF8F92A9), size: 40)),
                                )
                              : const Center(child: Icon(Icons.tv, color: Color(0xFF8F92A9), size: 40)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          series.name,
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
      List<Series> items = [];
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
      itemCount: _filteredSeries.length,
      itemBuilder: (context, index) {
        return _buildSeriesCard(_filteredSeries[index], width: 160);
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

  void _showDetails(Series series) async {
    await Navigator.push(
      context,
      SmoothPageRoute(child: SeriesDetailScreen(series: series)),
    );
    _loadSeries();
  }
}
