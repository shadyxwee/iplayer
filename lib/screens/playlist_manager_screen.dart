import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../services/m3u_parser.dart';
import '../services/epg_service.dart';
import '../services/xtream_service.dart';
import '../services/preferences_service.dart';
import '../l10n/app_localizations.dart';

class PlaylistManagerScreen extends StatefulWidget {
  const PlaylistManagerScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistManagerScreen> createState() => _PlaylistManagerScreenState();
}

class _PlaylistManagerScreenState extends State<PlaylistManagerScreen> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  int? _activePlaylistId;
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    _loadActivePlaylistId();
  }

  Future<void> _loadActivePlaylistId() async {
    final id = await PreferencesService.getActivePlaylistId();
    setState(() => _activePlaylistId = id);
  }

  Future<void> _usePlaylist(Playlist playlist) async {
    if (playlist.id == null) return;
    
    await PreferencesService.setActivePlaylistId(playlist.id);
    await _loadActivePlaylistId();
    _showSuccessSnackBar('Playlist "${playlist.name}" is now active');
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    final playlists = await DatabaseService.getAllPlaylists();
    setState(() {
      _playlists = playlists;
      _isLoading = false;
    });
  }

  Future<void> _addPlaylist() async {
    final result = await showDialog<Playlist>(
      context: context,
      builder: (context) => const PlaylistDialog(),
    );

    if (result != null) {
      await _processPlaylist(result);
    }
  }

  Future<void> _editPlaylist(Playlist playlist) async {
    final result = await showDialog<Playlist>(
      context: context,
      builder: (context) => PlaylistDialog(playlist: playlist),
    );

    if (result != null) {
      await _processPlaylist(result, isEdit: true);
    }
  }

  Future<void> _processPlaylist(Playlist playlist, {bool isEdit = false}) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(
        playlist: playlist,
        isEdit: isEdit,
      ),
    );

    try {
      List<Channel> channels = [];

      if (playlist.isXtreamCodes) {
        // Handle Xtream Codes source
        final service = XtreamService(
          baseUrl: playlist.url,
          username: playlist.username!,
          password: playlist.password!,
        );

        // Fetch LIVE CHANNELS
        final liveResult = await service.getLiveChannels();

        if (liveResult['success'] == true) {
          channels.addAll(liveResult['channels'] as List<Channel>);
        }

        // Fetch MOVIES (VOD)
        final moviesResult = await service.getMovies();

        if (moviesResult['success'] == true) {
          final movies = moviesResult['movies'] as List;

          for (var movie in movies) {
            final channel = Channel()
              ..name = movie.name
              ..url = movie.streamUrl
              ..logo = movie.posterUrl
              ..group = movie.categoryName
              ..description = movie.plot
              ..tvgId = movie.streamId // Save movie stream_id for metadata fetching
              ..contentType = ContentType.movie;
            channels.add(channel);
          }
        }

        // Fetch SERIES
        final seriesResult = await service.getSeries();

        if (seriesResult['success'] == true) {
          final seriesList = seriesResult['series'] as List;

          // For Xtream Codes, we save only ONE channel per series (metadata)
          // Episodes will be loaded on demand when the user enters series_grid_screen
          for (var series in seriesList) {
            // We use a special URL to identify it's an Xtream series
            // Format is: xtream://series/SERIES_ID
            final channel = Channel()
              ..name = series.name
              ..url = 'xtream://series/${series.id}'
              ..logo = series.posterUrl
              ..group = series.categoryName
              ..description = series.plot
              ..tvgId = int.tryParse(series.id) // Save series_id here
              ..contentType = ContentType.series;
            channels.add(channel);
          }
        }
      } else {
        // Handle M3U source
        channels = await M3UParser.parseFromUrl(playlist.getFullUrl());
      }

      // Save playlist first to get its ID
      playlist.channelCount = channels.length;
      playlist.lastUpdated = DateTime.now();
      await DatabaseService.addPlaylist(playlist);

      // If it's a new playlist, set it as active
      if (!isEdit) {
        // Associate channels with the playlist
        for (var channel in channels) {
          channel.playlistId = playlist.id;
        }
        await DatabaseService.addChannels(channels);

        // Set this playlist as active
        await PreferencesService.setActivePlaylistId(playlist.id);
      } else {
        // If it's an update, update the existing channels
        for (var channel in channels) {
          channel.playlistId = playlist.id;
        }
        await DatabaseService.addChannels(channels);
      }

      // Try to load EPG automatically (M3U only)
      String epgMessage = '';
      if (!playlist.isXtreamCodes) {
        final epgResult = await EpgService.loadEpgFromPlaylistUrl(playlist.getFullUrl());
        if (epgResult['success'] == true) {
          epgMessage = '\nEPG: ${l10n.epgUpdatedSuccess(epgResult['programs'])}';
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Count by content type
        final liveCount = channels.where((c) => c.contentType == ContentType.live).length;
        final movieCount = channels.where((c) => c.contentType == ContentType.movie).length;
        final seriesCount = channels.where((c) => c.contentType == ContentType.series).length;

        String message;
        if (playlist.isXtreamCodes) {
          message = isEdit
            ? l10n.xtreamPlaylistUpdated(liveCount, movieCount, seriesCount)
            : l10n.xtreamPlaylistAdded(liveCount, movieCount, seriesCount);
        } else {
          message = isEdit
            ? l10n.playlistUpdatedMsg(channels.length, epgMessage)
            : l10n.playlistAddedMsg(channels.length, epgMessage);
        }

        _showSuccessSnackBar(message);
      }

      _loadPlaylists();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<void> _refreshPlaylist(Playlist playlist) async {
    await _processPlaylist(playlist, isEdit: true);
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.deletePlaylistTitle,
              style: TextStyle(color: theme.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deletePlaylistConfirm(playlist.name),
              style: TextStyle(color: theme.textSecondary.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.deletePlaylistDesc(playlist.channelCount),
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deletePlaylist(playlist.id);
      _showSuccessSnackBar(l10n.playlistDeleted);
      _loadPlaylists();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPlaylistOptions(Playlist playlist, AppThemeType theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: theme.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: theme.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.playlist_play_rounded, color: Colors.black, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlist.channelCount} ${l10n.channelsLowercase}',
                          style: TextStyle(color: theme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (playlist.id != _activePlaylistId)
              _buildOptionTile(
                icon: Icons.play_circle_outline_rounded,
                label: 'Use this Playlist',
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  _usePlaylist(playlist);
                },
              ),
            _buildOptionTile(
              icon: Icons.edit_outlined,
              label: l10n.editPlaylistOption,
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                _editPlaylist(playlist);
              },
            ),
            _buildOptionTile(
              icon: Icons.refresh_rounded,
              label: l10n.refreshChannelsOption,
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                _refreshPlaylist(playlist);
              },
            ),
            _buildOptionTile(
              icon: Icons.calendar_month_rounded,
              label: l10n.updateEpgOption,
              theme: theme,
              onTap: () async {
                Navigator.pop(context);
                _updateEpg(playlist, theme);
              },
            ),
            _buildOptionTile(
              icon: Icons.info_outline_rounded,
              label: l10n.viewInfoOption,
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                _showPlaylistInfo(playlist, theme);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              label: l10n.deletePlaylistOption,
              theme: theme,
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                _deletePlaylist(playlist);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppThemeType theme,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? theme.textPrimary).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? theme.textSecondary, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? theme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
    );
  }

  Future<void> _updateEpg(Playlist playlist, AppThemeType theme) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Row(
          children: [
            CircularProgressIndicator(color: theme.accentPrimary),
            const SizedBox(width: 24),
            Text(l10n.updatingEpg, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );

    try {
      final result = await EpgService.loadEpgFromPlaylistUrl(playlist.getFullUrl());
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar(l10n.epgUpdatedSuccess(result['programs']));
      } else {
        _showErrorSnackBar(result['message'] ?? l10n.epgUpdateFailed);
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(l10n.epgUpdateError(e.toString()));
    }
  }

  void _showPlaylistInfo(Playlist playlist, AppThemeType theme) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          backgroundColor: theme.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: theme.accentPrimary),
              const SizedBox(width: 12),
              Text(
                l10n.information,
                style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(l10n.name, playlist.name, theme),
              _infoRow(l10n.channelsCount, '${playlist.channelCount}', theme),
              _infoRow(l10n.updated, _formatDateTime(playlist.lastUpdated, l10n), theme),
              _infoRow(l10n.authentication, playlist.username != null ? l10n.yes : l10n.no, theme),
              const SizedBox(height: 16),
              Text(
                l10n.url,
                style: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.backgroundTertiary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderPrimary.withOpacity(0.3)),
                ),
                child: SelectableText(
                  playlist.url,
                  style: TextStyle(color: theme.textSecondary, fontSize: 13, height: 1.4, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close, style: TextStyle(color: theme.accentPrimary, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value, AppThemeType theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: theme.textSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w800),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.accentPrimary))
            : CustomScrollView(
                slivers: [
                  // Premium App Bar / Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Row(
                        children: [
                          _buildTopActionButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.playlistManagement,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  'Manage your media sources',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildTopActionButton(Icons.help_outline_rounded, () => _showHelp(l10n, theme)),
                        ],
                      ),
                    ),
                  ),

                  if (_playlists.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(l10n, theme),
                    )
                  else ...[
                    // Playlists List
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final playlist = _playlists[index];
                            return _buildPlaylistCard(playlist, l10n, theme);
                          },
                          childCount: _playlists.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlaylist,
        backgroundColor: theme.accentPrimary,
        foregroundColor: Colors.black,
        elevation: 10,
        highlightElevation: 15,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: Text(
          l10n.newPlaylist,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildSmallButton(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, AppThemeType theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: theme.accentPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.playlist_add_rounded,
                size: 70,
                color: theme.accentPrimary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.noPlaylists,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addFirstPlaylist,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _addPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentPrimary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addPlaylist, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistList(AppThemeType theme) {
    final l10n = AppLocalizations.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _buildPlaylistCard(playlist, l10n, theme);
      },
    );
  }

  Widget _buildPlaylistCard(Playlist playlist, AppLocalizations l10n, AppThemeType theme) {
    final isActive = playlist.id == _activePlaylistId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isActive ? theme.accentPrimary.withOpacity(0.6) : Colors.white.withOpacity(0.05),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (isActive)
            BoxShadow(
              color: theme.accentPrimary.withOpacity(0.05),
              blurRadius: 30,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isActive) {
              _showPlaylistOptions(playlist, theme);
            } else {
              _usePlaylist(playlist);
            }
          },
          onLongPress: () => _showPlaylistOptions(playlist, theme),
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon/Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive 
                        ? theme.primaryGradient 
                        : [const Color(0xFF2A2A3E), const Color(0xFF1A1A2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    playlist.isXtreamCodes ? Icons.dns_rounded : Icons.playlist_play_rounded,
                    color: isActive ? Colors.black : Colors.white.withOpacity(0.6),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 24),
 
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              playlist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.accentPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: theme.accentPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Responsive info rows
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.video_library_rounded,
                            '${playlist.channelCount}',
                            theme: theme,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoChip(
                              Icons.update_rounded,
                              _formatDate(playlist.lastUpdated, l10n),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Use/Active Status & More
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive)
                      SizedBox(
                        width: 90,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () => _usePlaylist(playlist),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.accentPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: theme.accentPrimary.withOpacity(0.4),
                          ),
                          child: const Text(
                            'USE',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.accentPrimary.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.accentPrimary.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.check_rounded, color: theme.accentPrimary, size: 24),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSmallIconButton(Icons.refresh_rounded, theme.textSecondary.withOpacity(0.1), () => _refreshPlaylist(playlist), theme),
                        const SizedBox(width: 8),
                        _buildSmallIconButton(Icons.more_horiz_rounded, theme.textSecondary.withOpacity(0.1), () => _showPlaylistOptions(playlist, theme), theme),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, Color color, VoidCallback onTap, AppThemeType theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {required AppThemeType theme, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? theme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showHelp(AppLocalizations l10n, AppThemeType theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: theme.accentPrimary),
            const SizedBox(width: 12),
            Text(l10n.help, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _helpItem(l10n.supportedFormats, l10n.supportedFormatsDesc, theme),
              _helpItem(l10n.xtreamUrl, l10n.xtreamUrlDesc, theme),
              _helpItem(l10n.epg, l10n.epgDesc, theme),
              _helpItem(l10n.update, l10n.updateDesc, theme),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.understood, style: TextStyle(color: theme.accentPrimary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String title, String description, AppThemeType theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: theme.textSecondary, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.never;
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.never;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Diálogo de carga con progreso
class _LoadingDialog extends StatelessWidget {
  final Playlist playlist;
  final bool isEdit;

  const _LoadingDialog({required this.playlist, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.watch<ThemeProvider>().currentTheme;
    return AlertDialog(
      backgroundColor: theme.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          CircularProgressIndicator(color: theme.accentPrimary),
          const SizedBox(height: 24),
          Text(
            isEdit ? l10n.updatingPlaylist : l10n.loadingPlaylist,
            style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            style: TextStyle(color: theme.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.downloadingChannels,
            style: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Diálogo para agregar/editar playlist
class PlaylistDialog extends StatefulWidget {
  final Playlist? playlist;

  const PlaylistDialog({Key? key, this.playlist}) : super(key: key);

  @override
  State<PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _hostController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late PlaylistSourceType _sourceType;
  bool _isVerifying = false;
  bool _showPassword = false;
  String? _verificationMessage;

  bool get isEditing => widget.playlist != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist?.name ?? '');
    _urlController = TextEditingController(text: widget.playlist?.url ?? '');
    _usernameController = TextEditingController(text: widget.playlist?.username ?? '');
    _passwordController = TextEditingController(text: widget.playlist?.password ?? '');
    _hostController = TextEditingController(text: widget.playlist?.url ?? '');
    _sourceType = widget.playlist?.sourceType ?? PlaylistSourceType.m3u;

    // Add listeners for auto-detection
    _urlController.addListener(_handleUrlChange);
    _hostController.addListener(_handleUrlChange);
  }

  void _handleUrlChange() {
    final url = _sourceType == PlaylistSourceType.m3u 
        ? _urlController.text.trim() 
        : _hostController.text.trim();
    
    if (url.isEmpty) return;

    // Auto-detection of Xtream Codes from M3U URL
    if (url.contains('username=') && url.contains('password=') && (url.contains('get.php') || url.contains('player_api.php'))) {
      try {
        final uri = Uri.parse(url);
        final user = uri.queryParameters['username'];
        final pass = uri.queryParameters['password'];
        
        if (user != null && pass != null) {
          // Construct host preserving path but removing filename
          var hostPath = uri.path;
          if (hostPath.endsWith('/get.php')) {
            hostPath = hostPath.substring(0, hostPath.length - 8);
          } else if (hostPath.endsWith('/player_api.php')) {
            hostPath = hostPath.substring(0, hostPath.length - 15);
          }
          
          final host = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}$hostPath';
          
          if (_sourceType != PlaylistSourceType.xtreamCodes) {
            setState(() {
              _sourceType = PlaylistSourceType.xtreamCodes;
              _hostController.text = host;
              _usernameController.text = user;
              _passwordController.text = pass;
              
              // Try to set a name if empty
              if (_nameController.text.isEmpty) {
                _nameController.text = uri.host;
              }
            });
          }
        }
      } catch (_) {}
    } 
    // Auto-detect M3U if it ends with .m3u or .m3u8 but we are in Xtream mode
    else if ((url.endsWith('.m3u') || url.endsWith('.m3u8')) && _sourceType == PlaylistSourceType.xtreamCodes) {
      setState(() {
        _sourceType = PlaylistSourceType.m3u;
        _urlController.text = url;
      });
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_handleUrlChange);
    _hostController.removeListener(_handleUrlChange);
    _nameController.dispose();
    _urlController.dispose();
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyXtreamCredentials() async {
    final l10n = AppLocalizations.of(context);

    if (_hostController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _verificationMessage = l10n.completeAllFields);
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationMessage = null;
    });

    try {
      final service = XtreamService(
        baseUrl: _hostController.text.trim().replaceAll(RegExp(r'/*$'), ''),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final isValid = await service.verifyCredentials();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isVerifying = false;
          _verificationMessage = isValid ? l10n.credentialsVerified : l10n.credentialsInvalid;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verificationMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Dialog(
      backgroundColor: theme.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.accentPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.playlist_add,
                      color: theme.accentPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? l10n.editPlaylist : l10n.newPlaylist,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEditing ? l10n.modifyPlaylistSubtitle : l10n.addNewPlaylistSubtitle,
                        style: TextStyle(
                          color: theme.textSecondary.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Name field
              _buildTextField(
                controller: _nameController,
                label: l10n.playlistNameLabel,
                hint: l10n.playlistNameHint,
                icon: Icons.label_outline,
                theme: theme,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.playlistNameValidation;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Source Type Selector
              Container(
                decoration: BoxDecoration(
                  color: theme.textPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderPrimary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _sourceType = PlaylistSourceType.m3u),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _sourceType == PlaylistSourceType.m3u
                                ? theme.accentPrimary.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(_sourceType == PlaylistSourceType.m3u ? 12 : 8),
                            ),
                          ),
                          child: Text(
                            'M3U',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _sourceType = PlaylistSourceType.xtreamCodes),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _sourceType == PlaylistSourceType.xtreamCodes
                                ? theme.accentPrimary.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(_sourceType == PlaylistSourceType.xtreamCodes ? 12 : 8),
                            ),
                          ),
                          child: Text(
                            'Xtream Codes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // M3U Form
              if (_sourceType == PlaylistSourceType.m3u) ...[
                _buildTextField(
                  controller: _urlController,
                  label: l10n.playlistUrlLabel,
                  hint: l10n.playlistUrlHint,
                  icon: Icons.link,
                  maxLines: 2,
                  theme: theme,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.playlistUrlValidation;
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return l10n.urlValidationProtocol;
                    }
                    return null;
                  },
                ),
              ],

              // Xtream Codes Form
              if (_sourceType == PlaylistSourceType.xtreamCodes) ...[
                _buildTextField(
                  controller: _hostController,
                  label: l10n.serverHostLabel,
                  hint: l10n.serverHostHint,
                  icon: Icons.storage,
                  theme: theme,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.serverHostValidation;
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return l10n.protocolValidation;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _usernameController,
                        label: l10n.usernameLabel,
                        hint: l10n.usernameHint,
                        icon: Icons.person_outline,
                        theme: theme,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.usernameValidation;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _passwordController,
                        label: l10n.passwordLabel,
                        hint: l10n.passwordHint,
                        icon: Icons.lock_outline,
                        theme: theme,
                        obscureText: !_showPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.textSecondary.withOpacity(0.5),
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.passwordValidation;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Verification button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyXtreamCredentials,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.verifyCredentials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                if (_verificationMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _verificationMessage!.contains('verificadas')
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _verificationMessage!.contains('verificadas')
                            ? Colors.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _verificationMessage!,
                      style: TextStyle(
                        color: _verificationMessage!.contains('verificadas') ? Colors.green : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(isEditing ? Icons.save : Icons.add),
                    label: Text(isEditing ? l10n.save : l10n.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required AppThemeType theme,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(color: theme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: theme.textSecondary.withOpacity(0.7)),
        hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: theme.textSecondary.withOpacity(0.5)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.textPrimary.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderPrimary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.accentPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final playlist = widget.playlist ?? Playlist();
      playlist.name = _nameController.text.trim();
      playlist.sourceType = _sourceType;

      if (_sourceType == PlaylistSourceType.m3u) {
        playlist.url = _urlController.text.trim();
        playlist.username = null;
        playlist.password = null;
      } else {
        playlist.url = _hostController.text.trim().replaceAll(RegExp(r'/*$'), '');
        playlist.username = _usernameController.text.trim();
        playlist.password = _passwordController.text.trim();
      }

      playlist.lastUpdated = DateTime.now();

      if (widget.playlist == null) {
        playlist.isActive = true;
      }

      Navigator.pop(context, playlist);
    }
  }
}
