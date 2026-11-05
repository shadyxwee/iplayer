import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../models/playlist.dart';
import '../../services/database_service.dart';
import '../../services/config_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../services/preferences_service.dart';
import '../playlist_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTabIndex;

  const SettingsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Preferences & Config
  String _videoQuality = 'auto';
  bool _autoPlay = true;
  double _volume = 0.8;
  bool _showAdultContent = false;
  String _videoFit = 'contain';
  final TextEditingController _tmdbController = TextEditingController();
  final TextEditingController _omdbController = TextEditingController();
  bool _isSaving = false;

  bool _obscureTmdb = true;
  bool _obscureOmdb = true;

  // Playlists State
  List<Playlist> _playlists = [];
  Playlist? _activePlaylist;
  bool _isLoadingPlaylists = true;

  // Loved Categories State
  Set<String> _favoriteCategories = {};
  int _categoryTabTypeIndex = 0; // 0: Live TV, 1: Movies, 2: Series
  final TextEditingController _catSearchController = TextEditingController();
  String _catSearchQuery = '';
  Map<ContentType, List<String>> _categoriesByType = {
    ContentType.live: [],
    ContentType.movie: [],
    ContentType.series: [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );

    _tmdbController.text = ConfigService.getTmdbApiKey();
    _omdbController.text = ConfigService.getOmdbApiKey();

    _loadPlaylistsAndCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tmdbController.dispose();
    _omdbController.dispose();
    _catSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylistsAndCategories() async {
    setState(() => _isLoadingPlaylists = true);

    final playlists = await DatabaseService.getAllPlaylists();
    final activeId = await PreferencesService.getActivePlaylistId();
    Playlist? active;
    if (activeId != null) {
      active = await DatabaseService.getPlaylistById(activeId);
    }
    active ??= playlists.firstOrNull;

    final favs = await PreferencesService.getFavoriteCategories();

    // Fetch and aggregate all channel groups
    final allChannels = await DatabaseService.getAllChannels();
    final liveSet = <String>{};
    final movieSet = <String>{};
    final seriesSet = <String>{};

    for (final c in allChannels) {
      if (c.group != null && c.group!.trim().isNotEmpty) {
        if (c.contentType == ContentType.live) liveSet.add(c.group!);
        if (c.contentType == ContentType.movie) movieSet.add(c.group!);
        if (c.contentType == ContentType.series) seriesSet.add(c.group!);
      }
    }

    if (mounted) {
      setState(() {
        _playlists = playlists;
        _activePlaylist = active;
        _favoriteCategories = favs.toSet();
        _categoriesByType = {
          ContentType.live: liveSet.toList()..sort(),
          ContentType.movie: movieSet.toList()..sort(),
          ContentType.series: seriesSet.toList()..sort(),
        };
        _isLoadingPlaylists = false;
      });
    }
  }

  Future<void> _saveApiKeys() async {
    setState(() => _isSaving = true);
    await ConfigService.updateTmdbKey(_tmdbController.text.trim());
    await ConfigService.updateOmdbKey(_omdbController.text.trim());
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Configuration saved successfully')),
      );
    }
  }

  void _resetApiKeys() {
    setState(() {
      _tmdbController.text = '';
      _omdbController.text = '';
    });
    _saveApiKeys();
  }

  void _showAddPlaylistDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PlaylistDialog(),
    );
    await _loadPlaylistsAndCategories();
  }

  List<String> _getFilteredCategories() {
    ContentType type;
    if (_categoryTabTypeIndex == 0) {
      type = ContentType.live;
    } else if (_categoryTabTypeIndex == 1) {
      type = ContentType.movie;
    } else {
      type = ContentType.series;
    }
    final list = _categoriesByType[type] ?? [];
    if (_catSearchQuery.trim().isEmpty) return list;
    return list.where((c) => c.toLowerCase().contains(_catSearchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settings,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF0000),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFA1A1AA),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.playlist_play_rounded, size: 18), text: 'Playlists'),
            Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: 'Loved Categories'),
            Tab(icon: Icon(Icons.play_circle_outline_rounded, size: 18), text: 'Playback & Video'),
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'General & Security'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlaylistsTab(theme, l10n),
          _buildLovedCategoriesTab(theme, l10n),
          _buildVideoSettingsTab(theme, l10n),
          _buildGeneralSecurityTab(theme, themeProvider, l10n),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB 1: PLAYLISTS MANAGER
  // ---------------------------------------------------------
  Widget _buildPlaylistsTab(AppThemeType theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Playlists & Portals',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your M3U files, Xtream Codes, and Stalker / MAG portals.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddPlaylistDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Add Playlist / Portal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoadingPlaylists)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFFFF0000)),
                  ),
                )
              else if (_playlists.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.playlist_remove_rounded, color: Colors.white.withValues(alpha: 0.3), size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'No playlists added yet',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add an M3U playlist, Xtream Codes credentials, or a Stalker / MAG portal above.',
                        style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final pl = _playlists[index];
                    final isActive = _activePlaylist?.id == pl.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF202020) : const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? const Color(0xFFFF0000) : const Color(0xFF262626),
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFFF0000).withValues(alpha: 0.15)
                                  : const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              pl.isStalker
                                  ? Icons.router_rounded
                                  : pl.isXtreamCodes
                                      ? Icons.dns_rounded
                                      : Icons.playlist_play_rounded,
                              color: isActive ? const Color(0xFFFF0000) : Colors.white70,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      pl.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pl.isStalker
                                            ? 'Stalker / MAG'
                                            : (pl.isXtreamCodes ? 'Xtream Codes' : 'M3U File/URL'),
                                        style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  pl.isStalker
                                      ? 'MAC: ${pl.macAddress ?? 'N/A'} • URL: ${pl.url}'
                                      : pl.url,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (!isActive)
                            OutlinedButton(
                              onPressed: () async {
                                await PreferencesService.setActivePlaylistId(pl.id);
                                setState(() {
                                  _activePlaylist = pl;
                                });
                                _loadPlaylistsAndCategories();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF444444)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Set Active'),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Color(0xFFFF0000),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                            tooltip: 'Delete Playlist',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  title: const Text('Delete Playlist?', style: TextStyle(color: Colors.white)),
                                  content: Text('Are you sure you want to delete "${pl.name}"?',
                                      style: const TextStyle(color: Color(0xFFAAAAAA))),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888))),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await DatabaseService.deletePlaylist(pl.id);
                                await _loadPlaylistsAndCategories();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB 2: LOVED CATEGORIES (ADD TO VORTEXTUBE)
  // ---------------------------------------------------------
  Widget _buildLovedCategoriesTab(AppThemeType theme, AppLocalizations l10n) {
    final filteredCategories = _getFilteredCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loved Categories',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select favorite categories to build your personalized VortexTube feed (${_favoriteCategories.length} selected).',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter sub-tabs and search
              Row(
                children: [
                  _buildSubCategoryTab(0, 'Live TV Channels'),
                  const SizedBox(width: 8),
                  _buildSubCategoryTab(1, 'Movies / VOD'),
                  const SizedBox(width: 8),
                  _buildSubCategoryTab(2, 'TV Series'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF888888), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _catSearchController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Search categories...',
                                hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _catSearchQuery = val;
                                });
                              },
                            ),
                          ),
                          if (_catSearchQuery.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _catSearchController.clear();
                                setState(() {
                                  _catSearchQuery = '';
                                });
                              },
                              child: const Icon(Icons.close_rounded, color: Color(0xFF888888), size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (filteredCategories.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Center(
                    child: Text(
                      _catSearchQuery.isEmpty ? 'No categories available' : 'No categories match "$_catSearchQuery"',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 4.8,
                  ),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, idx) {
                    final cat = filteredCategories[idx];
                    final isFav = _favoriteCategories.contains(cat);

                    return InkWell(
                      onTap: () async {
                        final newFav = await PreferencesService.toggleFavoriteCategory(cat);
                        setState(() {
                          if (newFav) {
                            _favoriteCategories.add(cat);
                          } else {
                            _favoriteCategories.remove(cat);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isFav
                              ? const Color(0xFFFF0000).withValues(alpha: 0.12)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFav ? const Color(0xFFFF0000) : const Color(0xFF2A2A2A),
                            width: isFav ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? const Color(0xFFFF0000) : const Color(0xFF71717A),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isFav ? Colors.white : const Color(0xFFD4D4D8),
                                  fontWeight: isFav ? FontWeight.bold : FontWeight.w500,
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
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryTab(int subIdx, String label) {
    final isSelected = _categoryTabTypeIndex == subIdx;
    return InkWell(
      onTap: () {
        setState(() {
          _categoryTabTypeIndex = subIdx;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF262626) : const Color(0xFF181818),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.white70 : const Color(0xFF2E2E2E),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF888888),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB 3: VIDEO & PLAYBACK SETTINGS
  // ---------------------------------------------------------
  Widget _buildVideoSettingsTab(AppThemeType theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(l10n.videoSettings, theme),
              _buildSettingsCard(theme, [
                _buildDropdownTile(
                  icon: Icons.high_quality_rounded,
                  title: l10n.videoQuality,
                  value: _videoQuality.toUpperCase(),
                  onTap: () => _selectQuality(l10n, theme),
                  theme: theme,
                ),
                _buildDropdownTile(
                  icon: Icons.aspect_ratio_rounded,
                  title: l10n.videoFit,
                  value: _videoFit.toUpperCase(),
                  onTap: () => _selectVideoFit(l10n, theme),
                  theme: theme,
                ),
                _buildSwitchTile(
                  icon: Icons.play_arrow_rounded,
                  title: l10n.autoPlayOnSelect,
                  value: _autoPlay,
                  onChanged: (v) => setState(() => _autoPlay = v),
                  theme: theme,
                ),
                _buildSliderTile(
                  icon: Icons.volume_up_rounded,
                  title: l10n.defaultVolume,
                  value: _volume,
                  onChanged: (v) => setState(() => _volume = v),
                  theme: theme,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB 4: GENERAL, SECURITY & API KEYS
  // ---------------------------------------------------------
  Widget _buildGeneralSecurityTab(AppThemeType theme, ThemeProvider themeProvider, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('API & Metadata', theme),
              _buildMetadataCard(theme, l10n),
              const SizedBox(height: 32),

              _buildSectionHeader(l10n.theme, theme),
              _buildThemeGrid(theme, themeProvider),
              const SizedBox(height: 32),

              _buildSectionHeader(l10n.parentalControls, theme),
              _buildSettingsCard(theme, [
                _buildSwitchTile(
                  icon: Icons.block_rounded,
                  title: l10n.showAdultContent,
                  subtitle: l10n.requiresPin,
                  value: _showAdultContent,
                  onChanged: (value) {
                    if (value) _showPinDialog(theme);
                    else setState(() => _showAdultContent = false);
                  },
                  theme: theme,
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.vpn_key_rounded, color: theme.textSecondary, size: 20),
                  ),
                  title: const Text('Change Parental PIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, color: theme.accentPrimary, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  onTap: () => _changeParentalPin(theme),
                ),
              ]),
              const SizedBox(height: 32),

              _buildSectionHeader(l10n.dataManagement, theme),
              _buildSettingsCard(theme, [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                  ),
                  title: Text(l10n.clearAllData, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  subtitle: Text(l10n.clearDataConfirm, style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  onTap: () => _showClearDataDialog(theme),
                ),
              ]),
              const SizedBox(height: 32),

              _buildSectionHeader(l10n.about, theme),
              _buildSettingsCard(theme, [
                _buildInfoTile(Icons.info_outline_rounded, l10n.version, '1.2.0', theme),
                _buildInfoTile(Icons.code_rounded, 'Framework', 'Flutter SDK', theme),
                _buildInfoTile(Icons.storage_rounded, 'Engine', 'Media Kit + Isar + Rust Core', theme),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeType theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.textSecondary.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildThemeGrid(AppThemeType theme, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.5)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: AppThemeType.values.length,
        itemBuilder: (context, index) {
          final themeOption = AppThemeType.values[index];
          final isSelected = themeProvider.currentTheme == themeOption;

          return InkWell(
            onTap: () => themeProvider.setTheme(themeOption),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: themeOption.backgroundPrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.accentPrimary : theme.borderPrimary,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: theme.accentPrimary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: themeOption.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      themeOption.displayName,
                      style: TextStyle(
                        color: themeOption.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetadataCard(AppThemeType theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: theme.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.api_rounded, color: theme.accentPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TMDB & OMDB Integration', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('Provide custom API keys for rich posters, backdrops, and plots', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildApiKeyField(
            label: 'TheMovieDatabase (TMDB) API Key',
            controller: _tmdbController,
            obscureText: _obscureTmdb,
            onToggleObscure: () => setState(() => _obscureTmdb = !_obscureTmdb),
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildApiKeyField(
            label: 'Open Movie Database (OMDb) API Key',
            controller: _omdbController,
            obscureText: _obscureOmdb,
            onToggleObscure: () => setState(() => _obscureOmdb = !_obscureOmdb),
            theme: theme,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _resetApiKeys,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset Defaults'),
                style: TextButton.styleFrom(foregroundColor: theme.textSecondary),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveApiKeys,
                icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Keys', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentPrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildApiKeyField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required AppThemeType theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.backgroundTertiary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: 'Enter API Key',
              hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.4)),
              suffixIcon: IconButton(
                icon: Icon(obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: theme.textSecondary, size: 20),
                onPressed: onToggleObscure,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(AppThemeType theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderPrimary.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required AppThemeType theme,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.accentPrimary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, color: theme.textSecondary),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppThemeType theme,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.accentPrimary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: theme.accentPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required AppThemeType theme,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: theme.accentPrimary, size: 20),
          ),
          title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          trailing: Text('${(value * 100).round()}%', style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: theme.accentPrimary,
          inactiveColor: theme.backgroundTertiary,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, AppThemeType theme) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: theme.textSecondary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      trailing: Text(value, style: TextStyle(color: theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w700)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _selectQuality(AppLocalizations l10n, AppThemeType theme) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: theme.backgroundSecondary,
        title: Text(l10n.videoQuality, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900)),
        children: ['auto', '1080p', '720p', '480p'].map((q) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, q),
          child: Text(q.toUpperCase(), style: TextStyle(color: theme.textPrimary)),
        )).toList(),
      ),
    );
    if (result != null) setState(() => _videoQuality = result);
  }

  void _selectVideoFit(AppLocalizations l10n, AppThemeType theme) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: theme.backgroundSecondary,
        title: Text(l10n.videoFit, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900)),
        children: ['contain', 'cover', 'fitWidth', 'fitHeight'].map((f) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, f),
          child: Text(f.toUpperCase(), style: TextStyle(color: theme.textPrimary)),
        )).toList(),
      ),
    );
    if (result != null) setState(() => _videoFit = result);
  }

  Future<void> _showPinDialog(AppThemeType theme) async {
    final l10n = AppLocalizations.of(context);
    final currentPin = await PreferencesService.getParentalPin();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(l10n.enterPin, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: TextStyle(color: theme.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.enter4DigitPin,
              hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.borderPrimary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentPrimary)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentPrimary, foregroundColor: Colors.black),
              child: Text(l10n.ok, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    if (pin == currentPin) {
      setState(() => _showAdultContent = true);
    } else if (pin != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.incorrectPin)));
    }
  }

  Future<void> _changeParentalPin(AppThemeType theme) async {
    final l10n = AppLocalizations.of(context);
    final currentPin = await PreferencesService.getParentalPin();

    final currentInput = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Verify Current PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter current PIN',
              hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.borderPrimary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentPrimary)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentPrimary, foregroundColor: Colors.black),
              child: Text(l10n.ok, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    if (currentInput != currentPin) {
      if (currentInput != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.incorrectPin)));
      }
      return;
    }

    final newPin = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Enter New PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter 4-digit PIN',
              hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.borderPrimary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentPrimary)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentPrimary, foregroundColor: Colors.black),
              child: Text(l10n.ok, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    if (newPin != null && newPin.length == 4) {
      await PreferencesService.setParentalPin(newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parental PIN updated successfully')));
      }
    }
  }

  void _showClearDataDialog(AppThemeType theme) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundSecondary,
        title: Text(l10n.clearAllData, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900)),
        content: Text(l10n.clearDataConfirm, style: TextStyle(color: theme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.clearAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.allDataCleared)));
                _loadPlaylistsAndCategories();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text(l10n.clearAllData),
          ),
        ],
      ),
    );
  }
}
