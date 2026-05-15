import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/song.dart';
import '../../core/models/album.dart';
import '../../core/models/artist.dart';
import '../../core/models/playlist.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../core/utils/song_loader.dart';
import '../../features/player/player_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/error_state.dart';
import 'home_provider.dart';
import 'widgets/language_chips.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/song_card.dart';

// ─────────────────────────────────────────────────────────────
//  Home — Editorial Noir layout (Stitch 02_home_enhanced)
//  · Glass top bar with avatar + greeting (Playfair) + actions
//  · Quick Access glass grid
//  · Spotlight hero card with gradient overlay + play FAB
//  · Trending Now horizontal scroll (240px cards)
//  · Made For You grid
//  · Popular Artists row (circular)
// ─────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(selectedLanguageProvider);
    final feedAsync = ref.watch(homeFeedProvider(language));
    final continueListening = ref.watch(continueListeningProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          const _GlassHeader(),

          // Language chips (kept from old design — useful filter)
          const SliverToBoxAdapter(child: SizedBox(height: KaivaSpacing.sm)),
          const SliverToBoxAdapter(child: LanguageChips()),
          const SliverToBoxAdapter(child: SizedBox(height: KaivaSpacing.md)),

          // Quick Access glass grid
          if (continueListening.valueOrNull?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: KaivaSpacing.xl),
                child: QuickAccessGrid(
                  songs: continueListening.value!,
                  onTap: (song, index) =>
                      _playSong(ref, continueListening.value!, index),
                ),
              ),
            ),

          feedAsync.when(
            loading: () => const SliverToBoxAdapter(child: _ShimmerFeed()),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorState(
                message: isOnline
                    ? 'Could not load music. The server may be down.'
                    : "You're offline. No downloaded songs yet.",
                onRetry: isOnline
                    ? () => ref.invalidate(homeFeedProvider(language))
                    : null,
              ),
            ),
            data: (feed) => SliverList(
              delegate: SliverChildListDelegate([
                // ── Spotlight ─────────────────────────────────
                if (feed.trending.isNotEmpty) ...[
                  _SpotlightCard(
                    song: feed.trending.first,
                    onPlay: () => _playSong(ref, feed.trending, 0),
                  ),
                  const SizedBox(height: KaivaSpacing.xl),
                ],

                // ── Trending Now ──────────────────────────────
                if (feed.trending.length > 1) ...[
                  _SectionHeader(
                    title: isOnline ? 'Trending Now' : 'Your Music',
                    showAll: isOnline ? 'Show All' : null,
                    onShowAll: isOnline
                        ? () => context.push(
                            '/search/results?q=${Uri.encodeComponent("trending")}',
                          )
                        : null,
                  ),
                  const SizedBox(height: KaivaSpacing.md),
                  _HorizontalSongs(
                    songs: feed.trending.skip(1).toList(),
                    onTap: (song, idx) =>
                        _playSong(ref, feed.trending, idx + 1),
                  ),
                  const SizedBox(height: KaivaSpacing.xl),
                ],

                // ── New Releases ──────────────────────────────
                if (feed.newReleases.isNotEmpty) ...[
                  _SectionHeader(title: 'New Releases'),
                  const SizedBox(height: KaivaSpacing.md),
                  _HorizontalAlbums(albums: feed.newReleases),
                  const SizedBox(height: KaivaSpacing.xl),
                ],

                // ── Made For You (curated playlists) ──────────
                if (feed.featuredPlaylists.isNotEmpty) ...[
                  _SectionHeader(title: 'Made For You'),
                  const SizedBox(height: KaivaSpacing.md),
                  _MadeForYouGrid(playlists: feed.featuredPlaylists),
                  const SizedBox(height: KaivaSpacing.xl),
                ],

                // ── Popular Artists ───────────────────────────
                if (feed.popularArtists.isNotEmpty) ...[
                  _SectionHeader(title: 'Artists For You'),
                  const SizedBox(height: KaivaSpacing.md),
                  _HorizontalArtists(artists: feed.popularArtists),
                  const SizedBox(height: KaivaSpacing.xl),
                ],

                // ── Moods & Moments ───────────────────────────
                _SectionHeader(title: 'Moods & Moments'),
                const SizedBox(height: KaivaSpacing.md),
                const _MoodChips(),
                const SizedBox(height: 160), // bottom padding for mini player + nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playSong(WidgetRef ref, List<Song> songs, int index) async {
    final handler = ref.read(audioHandlerProvider);
    final reordered = [
      songs[index],
      ...songs.sublist(0, index),
      ...songs.sublist(index + 1),
    ];
    final fresh = await fetchFreshQueue(reordered);
    await handler.playQueue(fresh, 0);
  }
}

// ─── Glass Header ───────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  const _GlassHeader();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: KaivaColors.backgroundPrimary.withValues(alpha: 0.8),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: KaivaSpacing.marginMobile,
              right: KaivaSpacing.marginMobile,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KaivaColors.surfaceContainerHigh,
                    border: Border.all(color: KaivaColors.borderDefault, width: 1),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: KaivaColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: KaivaSpacing.sm),
                // Greeting (Playfair, warm-sand color per Stitch)
                Expanded(
                  child: Text(
                    greeting,
                    style: KaivaTextStyles.headlineLarge.copyWith(
                      color: KaivaColors.accentBright,
                      letterSpacing: -0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  iconSize: 26,
                  color: KaivaColors.textSecondary,
                  onPressed: () => context.go('/search'),
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  iconSize: 26,
                  color: KaivaColors.textSecondary,
                  onPressed: () => context.push('/settings'),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section header (Playfair display title + optional Show All) ──
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? showAll;
  final VoidCallback? onShowAll;

  const _SectionHeader({required this.title, this.showAll, this.onShowAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: KaivaTextStyles.displayLarge.copyWith(fontSize: 32),
            ),
          ),
          if (showAll != null)
            TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(
                foregroundColor: KaivaColors.accentPrimary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 32),
              ),
              child: Text(
                showAll!.toUpperCase(),
                style: KaivaTextStyles.labelSmall.copyWith(
                  color: KaivaColors.accentPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Spotlight hero card ────────────────────────────────────
class _SpotlightCard extends StatelessWidget {
  final Song song;
  final VoidCallback onPlay;

  const _SpotlightCard({required this.song, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPlay();
        },
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KaivaRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Artwork
                song.artworkUrl.isEmpty
                    ? Container(color: KaivaColors.surfaceContainerHigh)
                    : CachedNetworkImage(
                        imageUrl: song.artworkUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: KaivaColors.surfaceContainerHigh),
                        errorWidget: (_, __, ___) =>
                            Container(color: KaivaColors.surfaceContainerHigh),
                      ),
                // Gradient overlay
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x66000000),
                        Color(0xE6000000),
                      ],
                      stops: [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                // Subtle border overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(KaivaRadius.lg),
                    border: Border.all(
                      color: KaivaColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                ),
                // Bottom-left text + play FAB
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRENDING NOW',
                                style: KaivaTextStyles.labelSmall.copyWith(
                                  color: KaivaColors.accentPrimary,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.title,
                                style: KaivaTextStyles.displayMedium.copyWith(
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.artist,
                                style: KaivaTextStyles.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: KaivaColors.accentPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66EF9F27),
                                blurRadius: 32,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: KaivaColors.textOnAccent,
                            size: 36,
                          ),
                        ),
                      ],
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

// ─── Trending row (240px Stitch-style cards) ────────────────
class _HorizontalSongs extends StatelessWidget {
  final List<Song> songs;
  final void Function(Song, int) onTap;

  const _HorizontalSongs({required this.songs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 332,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: KaivaSpacing.gutter),
        itemBuilder: (context, i) => SongCard(
          song: songs[i],
          onTap: () => onTap(songs[i], i),
        ),
      ),
    );
  }
}

// ─── Horizontal albums row (matches new-release look) ───────
class _HorizontalAlbums extends StatelessWidget {
  final List<Album> albums;
  const _HorizontalAlbums({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: KaivaSpacing.sm),
        itemBuilder: (context, i) {
          final album = albums[i];
          return SizedBox(
            width: 168,
            child: AlbumCard(
              title: album.name,
              subtitle: album.artistName ?? '',
              artworkUrl: album.artworkUrl,
              onTap: () => context.push('/album/${album.id}'),
            ),
          );
        },
      ),
    );
  }
}

// ─── Made-For-You 2-col grid ────────────────────────────────
class _MadeForYouGrid extends StatelessWidget {
  final List<Playlist> playlists;
  const _MadeForYouGrid({required this.playlists});

  @override
  Widget build(BuildContext context) {
    final items = playlists.take(6).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: KaivaSpacing.gutter,
          mainAxisSpacing: KaivaSpacing.md,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, i) {
          final pl = items[i];
          return AlbumCard(
            title: pl.name,
            subtitle: pl.description ?? '',
            artworkUrl: pl.artworkUrl,
            onTap: () => context.push('/playlist/${pl.id}'),
          );
        },
      ),
    );
  }
}

// ─── Horizontal artists row ─────────────────────────────────
class _HorizontalArtists extends StatelessWidget {
  final List<Artist> artists;
  const _HorizontalArtists({required this.artists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: KaivaSpacing.md),
        itemBuilder: (context, i) {
          final artist = artists[i];
          return ArtistCircle(
            name: artist.name,
            imageUrl: artist.imageUrl,
            onTap: () => context.push('/artist/${artist.id}'),
          );
        },
      ),
    );
  }
}

// ─── Mood chips (kept; warm-sand themed) ───────────────────
typedef _Mood = ({String label, IconData icon, String searchQuery});

class _MoodChips extends StatelessWidget {
  const _MoodChips();

  static const List<_Mood> _moods = [
    (label: 'Morning', icon: Icons.wb_sunny_outlined, searchQuery: 'morning vibes'),
    (label: 'Workout', icon: Icons.fitness_center_rounded, searchQuery: 'workout energy'),
    (label: 'Focus', icon: Icons.self_improvement_rounded, searchQuery: 'focus study'),
    (label: 'Chill', icon: Icons.waves_rounded, searchQuery: 'chill relax'),
    (label: 'Party', icon: Icons.celebration_rounded, searchQuery: 'party hits'),
    (label: 'Sleep', icon: Icons.bedtime_outlined, searchQuery: 'sleep calm'),
    (label: 'Romance', icon: Icons.favorite_outline_rounded, searchQuery: 'romantic love'),
    (label: 'Devotional', icon: Icons.temple_hindu_outlined, searchQuery: 'devotional bhajan'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KaivaSpacing.marginMobile),
        itemCount: _moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: KaivaSpacing.sm),
        itemBuilder: (context, i) {
          final mood = _moods[i];
          return GestureDetector(
            onTap: () => context.push(
              '/search/results?q=${Uri.encodeComponent(mood.searchQuery)}',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: KaivaColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(KaivaRadius.base),
                border: Border.all(color: KaivaColors.borderSubtle, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mood.icon, size: 16, color: KaivaColors.accentPrimary),
                  const SizedBox(width: 8),
                  Text(
                    mood.label,
                    style: KaivaTextStyles.labelLarge,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Shimmer placeholder ────────────────────────────────────
class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: KaivaSpacing.md),
        ShimmerHorizontalList(),
        SizedBox(height: KaivaSpacing.xl),
        ShimmerHorizontalList(),
        SizedBox(height: KaivaSpacing.xl),
        ShimmerHorizontalList(),
      ],
    );
  }
}
