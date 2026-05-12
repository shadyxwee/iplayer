import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../services/m3u_parser.dart';
import '../services/tmdb_service.dart';
import '../widgets/content_widgets.dart';
import '../providers/theme_provider.dart';
import '../services/preferences_service.dart';
import 'package:provider/provider.dart';
import 'mobile_movie_detail_screen.dart';
import 'mobile_video_player_screen.dart';

class MobileMoviesScreen extends StatefulWidget {
  const MobileMoviesScreen({Key? key}) : super(key: key);

  @override
  State<MobileMoviesScreen> createState() => _MobileMoviesScreenState();
}

class _MobileMoviesScreenState extends State<MobileMoviesScreen> {
  List<Channel> _allMovies = [];
  List<Channel> _filteredMovies = [];
  List<Channel> _trendingMovies = [];
  List<Channel> _recentMovies = [];
  List<Channel> _favoriteMovies = [];
  Map<String, List<Channel>> _groupedMovies = {};
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'added';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final activePlaylistId = await PreferencesService.getActivePlaylistId();
    final allChannels = activePlaylistId != null 
        ? await DatabaseService.getChannelsByPlaylistId(activePlaylistId)
        : await DatabaseService.getAllChannels();
    final movies = allChannels
        .where((c) => c.contentType == ContentType.movie)
        .toList();

    final grouped = M3UParser.groupChannels(movies);

    // Trending: Top rated movies (rating >= 7.0)
    final trending = movies.where((m) => m.rating >= 7.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final trendingList = trending.take(20).toList();

    // Recent: Last watched movies
    final recent = movies.where((m) => m.playCount > 0).toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final recentList = recent.take(20).toList();

    // Favorites
    final favorites = movies.where((m) => m.isFavorite).toList();

    if (mounted) {
      setState(() {
        _allMovies = movies;
        _filteredMovies = movies;
        _groupedMovies = grouped;
        _trendingMovies = trendingList;
        _recentMovies = recentList;
        _favoriteMovies = favorites;
        _isLoading = false;
      });

      // Load ratings in background
      _loadRatings(movies);
    }
  }

  Future<void> _loadRatings(List<Channel> movies) async {
    for (final movie in movies) {
      if (!mounted) return;

      if (movie.rating == 0) {
        final cleanedName = TmdbService.cleanContentName(movie.name);
        final rating = await TmdbService.getMovieRatingFromApi(cleanedName);

        if (rating != null && rating > 0) {
          await DatabaseService.updateChannelRating(movie, rating);
          if (mounted) {
            setState(() {
              movie.rating = rating;
            });
          }
        }
      }

      if (movie.description == null || movie.description!.isEmpty) {
        final cleanedName = TmdbService.cleanContentName(movie.name);
        final description = await TmdbService.getMovieDescription(cleanedName);

        if (description != null && description.isNotEmpty) {
          movie.description = description;
          await DatabaseService.isar.writeTxn(() async {
            await DatabaseService.isar.channels.put(movie);
          });
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  void _filterMovies() {
    List<Channel> filtered = _allMovies;

    if (_selectedCategory != null && _selectedCategory != 'All' && _selectedCategory != AppLocalizations.of(context).all) {
      filtered = filtered
          .where((c) => c.group == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort
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
      _filteredMovies = filtered;
    });
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
                  : _buildMovieGrid(l10n, theme),
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
                          child: _buildMovieGrid(l10n, theme),
                        ),
                      ],
                    ),
              ),
            ],
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
                _buildSidebarItem('All', l10n.all, Icons.movie_rounded),
                ..._groupedMovies.keys.map((cat) => _buildSidebarItem(cat, cat, Icons.folder_rounded)),
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
        _filterMovies();
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

  Widget _buildHorizontalCategories(AppLocalizations l10n, AppThemeType theme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', l10n.all),
          ..._groupedMovies.keys.map((cat) => _buildCategoryChip(cat, cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value || (value == 'All' && _selectedCategory == null);
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = value == 'All' ? null : value);
        _filterMovies();
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
                  l10n.movies,
                  style: TextStyle(color: Colors.white, fontSize: isPortrait ? 18 : 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_filteredMovies.length} ${l10n.movies}',
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
        _filterMovies();
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
        _filterMovies();
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

  Widget _buildMovieGrid(AppLocalizations l10n, AppThemeType theme) {
    if (_filteredMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(l10n.noMovies, style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
      itemCount: _filteredMovies.length,
      itemBuilder: (context, index) => ContentGridCard(
        channel: _filteredMovies[index],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MobileMovieDetailScreen(movie: _filteredMovies[index])),
        ),
      ),
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

