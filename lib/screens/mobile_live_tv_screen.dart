import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../services/database_service.dart';
import '../services/m3u_parser.dart';
import '../widgets/content_widgets.dart';
import '../providers/theme_provider.dart';
import '../services/preferences_service.dart';
import 'package:provider/provider.dart';
import 'mobile_video_player_screen.dart';

class MobileLiveTVScreen extends StatefulWidget {
  const MobileLiveTVScreen({Key? key}) : super(key: key);

  @override
  State<MobileLiveTVScreen> createState() => _MobileLiveTVScreenState();
}

class _MobileLiveTVScreenState extends State<MobileLiveTVScreen> {
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  List<Channel> _recentChannels = [];
  Map<String, List<Channel>> _groupedChannels = {};
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    final activePlaylistId = await PreferencesService.getActivePlaylistId();
    final allChannels = activePlaylistId != null 
        ? await DatabaseService.getChannelsByPlaylistId(activePlaylistId)
        : await DatabaseService.getAllChannels();
    final liveChannels = allChannels
        .where((c) => c.contentType == ContentType.live)
        .toList();

    final grouped = M3UParser.groupChannels(liveChannels);
    final recent = await DatabaseService.getRecentlyPlayedChannels(limit: 10);
    final filteredRecent = recent.where((c) => c.contentType == ContentType.live).toList();

    if (mounted) {
      setState(() {
        _allChannels = liveChannels;
        _filteredChannels = liveChannels;
        _groupedChannels = grouped;
        _recentChannels = filteredRecent;
        _isLoading = false;
      });
    }
  }

  void _filterChannels() {
    List<Channel> filtered = _allChannels;

    if (_selectedCategory != null && _selectedCategory != 'All' && _selectedCategory != AppLocalizations.of(context).all) {
      filtered = filtered
          .where((c) => c.group == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (c.number?.toString().contains(_searchQuery) ?? false))
          .toList();
    }

    setState(() {
      _filteredChannels = filtered;
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
                  : _buildChannelGrid(l10n, theme),
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
                          child: _buildChannelGrid(l10n, theme),
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
          ..._groupedChannels.keys.map((cat) => _buildCategoryChip(cat, cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value || (value == 'All' && _selectedCategory == null);
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = value == 'All' ? null : value);
        _filterChannels();
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
                _buildSidebarItem('All', l10n.all, Icons.grid_view_rounded),
                ..._groupedChannels.keys.map((cat) => _buildSidebarItem(cat, cat, Icons.folder_rounded)),
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
        _filterChannels();
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
                  l10n.liveTV,
                  style: TextStyle(color: Colors.white, fontSize: isPortrait ? 18 : 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_filteredChannels.length} ${l10n.channels}',
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
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n, AppThemeType theme) {
    return TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _filterChannels();
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

  Widget _buildChannelGrid(AppLocalizations l10n, AppThemeType theme) {
    if (_filteredChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(l10n.noChannels, style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180, // Ensuring cards don't occupy maximum screen
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredChannels.length,
      itemBuilder: (context, index) => _buildLiveChannelCard(_filteredChannels[index], theme),
    );
  }

  Widget _buildLiveChannelCard(Channel channel, AppThemeType theme) {
    return _FocusableButton(
      onTap: () => _playChannel(channel),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: focused ? theme.accentPrimary : Colors.white.withOpacity(0.05), width: 2),
          boxShadow: focused ? [BoxShadow(color: theme.accentPrimary.withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: channel.logo != null && channel.logo!.isNotEmpty
                        ? Image.network(
                            channel.logo!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(Icons.tv, color: Colors.white.withOpacity(0.1), size: 40),
                          )
                        : Icon(Icons.tv, color: Colors.white.withOpacity(0.1), size: 40),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Text(
                channel.name,
                style: TextStyle(
                  color: focused ? theme.accentPrimary : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _playChannel(Channel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MobileVideoPlayerScreen(channel: channel)),
    ).then((_) => _loadChannels());
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


