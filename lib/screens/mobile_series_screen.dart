import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../services/tmdb_service.dart';
import '../widgets/content_widgets.dart';
import '../providers/theme_provider.dart';
import '../services/preferences_service.dart';
import 'package:provider/provider.dart';
import 'mobile_series_detail_screen.dart';
import 'mobile_video_player_screen.dart';

class MobileSeriesScreen extends StatefulWidget {
  const MobileSeriesScreen({Key? key}) : super(key: key);

  @override
  State<MobileSeriesScreen> createState() => _MobileSeriesScreenState();
}

class _MobileSeriesScreenState extends State<MobileSeriesScreen> {
  Map<String, List<Channel>> _groupedSeries = {};
  Map<String, Channel> _seriesRepresentatives = {};
  Map<String, List<String>> _groupedByCategory = {};
  List<String> _seriesTitles = [];
  List<String> _filteredSeriesTitles = [];
  List<String> _trendingSeries = [];
  List<String> _recentSeries = [];
  List<String> _favoriteSeries = [];
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'added';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final activePlaylistId = await PreferencesService.getActivePlaylistId();
    final allChannels = activePlaylistId != null 
        ? await DatabaseService.getChannelsByPlaylistId(activePlaylistId)
        : await DatabaseService.getAllChannels();
    final series = allChannels
        .where((c) => c.contentType == ContentType.series)
        .toList();

    final Map<String, List<Channel>> groupedBySeriesName = {};
    final Map<String, Channel> representatives = {};

    for (final episode in series) {
      final seriesName = _extractSeriesName(episode.name);
      if (!groupedBySeriesName.containsKey(seriesName)) {
        groupedBySeriesName[seriesName] = [];
        representatives[seriesName] = episode;
      }
      groupedBySeriesName[seriesName]!.add(episode);
    }

    final seriesTitles = groupedBySeriesName.keys.toList();

    // Trending & Favorites
    final List<String> trending = seriesTitles.where((t) => (representatives[t]?.rating ?? 0) >= 7.0).toList()
      ..sort((a, b) => (representatives[b]?.rating ?? 0).compareTo(representatives[a]?.rating ?? 0));
    
    final List<String> favorites = seriesTitles.where((t) => representatives[t]?.isFavorite ?? false).toList();
    
    // Recent (based on play counts of episodes)
    final List<String> recent = seriesTitles.where((t) => 
      groupedBySeriesName[t]!.any((e) => e.playCount > 0)).toList();

    final Map<String, List<String>> groupedByCategory = {};
    final l10n = AppLocalizations.of(context);
    for (final seriesName in seriesTitles) {
      final category = representatives[seriesName]?.group ?? l10n.noCategory;
      if (!groupedByCategory.containsKey(category)) {
        groupedByCategory[category] = [];
      }
      groupedByCategory[category]!.add(seriesName);
    }

    if (mounted) {
      setState(() {
        _groupedSeries = groupedBySeriesName;
        _seriesRepresentatives = representatives;
        _groupedByCategory = groupedByCategory;
        _seriesTitles = seriesTitles;
        _filteredSeriesTitles = seriesTitles;
        _trendingSeries = trending.take(15).toList();
        _recentSeries = recent.take(15).toList();
        _favoriteSeries = favorites;
        _isLoading = false;
      });

      _loadRatings(representatives.values.toList());
    }
  }

  String _extractSeriesName(String fullName) {
    String cleaned = fullName;
    cleaned = cleaned.replaceAll(RegExp(r'\s*[Ss]\d+[Ee]\d+.*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\d+x\d+.*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*[Ee]p(isode)?\s*\d+.*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*[Ss]eason\s*\d+.*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*[-:]\s*\d+.*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\d+\s*$'), '');
    return cleaned.trim();
  }

  Future<void> _loadRatings(List<Channel> representatives) async {
    for (final show in representatives) {
      if (!mounted) return;
      if (show.rating == 0) {
        final cleanedName = TmdbService.cleanContentName(show.name);
        final rating = await TmdbService.getMovieRatingFromApi(cleanedName);
        if (rating != null && rating > 0) {
          await DatabaseService.updateChannelRating(show, rating);
          if (mounted) setState(() => show.rating = rating);
        }
      }
    }
  }

  void _filterSeries() {
    List<String> filtered = _seriesTitles;
    if (_selectedCategory != null && _selectedCategory != 'All' && _selectedCategory != AppLocalizations.of(context).all) {
      filtered = filtered.where((title) => _seriesRepresentatives[title]?.group == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((title) => title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    setState(() => _filteredSeriesTitles = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: isPortrait 
        ? Column(
            children: [
              _buildHeader(l10n, theme),
              if (!_isLoading) _buildHorizontalCategories(l10n, theme),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : _buildSeriesGrid(l10n, theme),
              ),
            ],
          )
        : Row(
            children: [
              // Sidebar categories
              if (!_isLoading) _buildSidebar(l10n, theme),
              
              // Main Content
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : Column(
                      children: [
                        _buildHeader(l10n, theme),
                        Expanded(
                          child: _buildSeriesGrid(l10n, theme),
                        ),
                      ],
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildHorizontalCategories(AppLocalizations l10n, AppThemeType theme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', l10n.all),
          ..._groupedByCategory.keys.map((cat) => _buildCategoryChip(cat, cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value || (value == 'All' && _selectedCategory == null);
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = value == 'All' ? null : value);
        _filterSeries();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations l10n, AppThemeType theme) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF161625),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.categories.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem('All', l10n.all, Icons.movie_filter_rounded),
                ..._groupedByCategory.keys.map((cat) => _buildSidebarItem(cat, cat, Icons.folder_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value || (value == 'All' && _selectedCategory == null);
    
    return _FocusableButton(
      onTap: () {
        setState(() => _selectedCategory = value == 'All' ? null : value);
        _filterSeries();
      },
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: focused ? Colors.white.withOpacity(0.1) : (isSelected ? const Color(0xFF8B5CF6).withOpacity(0.15) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: focused ? const Color(0xFF8B5CF6) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected || focused ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected || focused ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected || focused ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AppThemeType theme) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    return Padding(
      padding: EdgeInsets.all(isPortrait ? 16 : 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.series,
                  style: TextStyle(color: Colors.white, fontSize: isPortrait ? 18 : 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_filteredSeriesTitles.length} ${l10n.series}',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          if (!isPortrait) const SizedBox(width: 16),
          SizedBox(
            width: isPortrait ? 150 : 300,
            child: _buildSearchField(l10n, theme),
          ),
          const SizedBox(width: 8),
          _buildSortButton(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildSortButton(AppLocalizations l10n, AppThemeType theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort_rounded, color: Colors.white),
      onSelected: (value) {
        setState(() => _sortBy = value);
        _filterSeries();
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'added', child: Text(l10n.sortByAdded)),
        PopupMenuItem(value: 'name', child: Text(l10n.sortByName)),
        PopupMenuItem(value: 'rating', child: Text(l10n.sortByRating)),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n, AppThemeType theme) {
    return TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _filterSeries();
      },
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: l10n.search,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5), size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      ),
    );
  }

  Widget _buildSeriesGrid(AppLocalizations l10n, AppThemeType theme) {
    if (_filteredSeriesTitles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(l10n.noSeries, style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180, // Ensuring cards don't occupy maximum screen
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredSeriesTitles.length,
      itemBuilder: (context, index) {
        final title = _filteredSeriesTitles[index];
        final representative = _seriesRepresentatives[title]!;
        return ContentGridCard(
          channel: representative,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MobileSeriesDetailScreen(
              series: representative, 
              episodes: _groupedSeries[title]!, 
              seriesTitle: title,
            )),
          ),
        );
      },
    );
  }
}

class _FocusableButton extends StatefulWidget {
  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback onTap;

  const _FocusableButton({required this.builder, required this.onTap});

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
      onShowFocusHighlight: (val) => setState(() => _isFocused = val),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.builder(context, _isFocused),
      ),
    );
  }
}

