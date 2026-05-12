import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ContentHeroBanner extends StatelessWidget {
  final Channel featured;
  final VoidCallback onPlay;
  final VoidCallback onMoreInfo;

  const ContentHeroBanner({
    Key? key,
    required this.featured,
    required this.onPlay,
    required this.onMoreInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.backgroundPrimary,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with gradient mask
          if (featured.logo != null && featured.logo!.isNotEmpty)
            ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.network(
                featured.logo!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme),
              ),
            )
          else
            _buildPlaceholder(theme),

          // Bottom & Side Gradients to blend
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.backgroundPrimary.withOpacity(0.8),
                  theme.backgroundPrimary,
                ],
                stops: const [0.3, 0.8, 1.0],
              ),
            ),
          ),

          // Content
          Positioned(
            left: 20,
            bottom: 30,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accentPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.featuredBadge.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  featured.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    shadows: [
                      Shadow(offset: Offset(0, 2), blurRadius: 10, color: Colors.black),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Rating & Category
                Row(
                  children: [
                    if (featured.rating > 0) ...[
                      _buildRatingBadge(featured.rating),
                      const SizedBox(width: 8),
                    ],
                    if (featured.group != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          featured.group!,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentPrimary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.playButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMoreInfo,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                        label: Text(l10n.moreInfo),
                      ),
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

  Widget _buildPlaceholder(AppThemeType theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.cardBackground, theme.backgroundPrimary],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.getRatingColor(rating),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 12),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTrailingTap;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.icon,
    this.onTrailingTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: theme.accentPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (onTrailingTap != null)
            IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded, color: theme.textSecondary.withOpacity(0.5), size: 16),
              onPressed: onTrailingTap,
            ),
        ],
      ),
    );
  }
}

class ContentGridCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onTap;
  final bool showProgress;
  final double? progress;

  const ContentGridCard({
    Key? key,
    required this.channel,
    required this.onTap,
    this.showProgress = false,
    this.progress,
  }) : super(key: key);

  @override
  State<ContentGridCard> createState() => _ContentGridCardState();
}

class _ContentGridCardState extends State<ContentGridCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return FocusableActionDetector(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      autofocus: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: _isFocused ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused ? theme.accentPrimary : Colors.white.withOpacity(0.05),
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: _isFocused ? [
            BoxShadow(
              color: theme.accentPrimary.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.channel.logo != null && widget.channel.logo!.isNotEmpty)
                          Image.network(
                            widget.channel.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme),
                          )
                        else
                          _buildPlaceholder(theme),
                        
                        // Progress Bar Overlay
                        if (widget.showProgress && widget.progress != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              color: Colors.white24,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: widget.progress!.clamp(0.0, 1.0),
                                child: Container(color: theme.accentPrimary),
                              ),
                            ),
                          ),

                        // Rating Badge
                        if (widget.channel.rating > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 10),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.channel.rating.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.channel.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.channel.group ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppThemeType theme) {
    return Container(
      color: theme.backgroundTertiary,
      child: Center(
        child: Icon(Icons.movie_rounded, color: Colors.white.withOpacity(0.1), size: 40),
      ),
    );
  }
}
