import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/song.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(selectedLanguageProvider);
    final feedAsync = ref.watch(homeFeedProvider(language));
    final continueListening = ref.watch(continueListeningProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: LanguageChips()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // ── Quick-access grid (Spotify-style 2-col recent cards) ──
          if (continueListening.valueOrNull?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  QuickAccessGrid(
                    songs: continueListening.value!,
                    onTap: (song, index) =>
                        _playSong(ref, continueListening.value!, index),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          feedAsync.when(
            loading: () => const SliverToBoxAdapter(child: _ShimmerFeed()),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorState(
                message: isOnline
                    ? 'Could not load music. The server may be down.'
                    : 'You\'re offline. No downloaded songs yet.',
                onRetry: isOnline
                    ? () => ref.invalidate(homeFeedProvider(language))
                    : null,
              ),
            ),
            data: (feed) => SliverList(
              delegate: SliverChildListDelegate([
                if (feed.trending.isNotEmpty) ...[
                  _Section(
                    title: isOnline ? 'TRENDING NOW' : 'YOUR MUSIC',
                    child: _HorizontalSongs(
                      songs: feed.trending,
                      onTap: (song, index) => _playSong(ref, feed.trending, index),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (feed.newReleases.isNotEmpty) ...[
                  _Section(
                    title: 'NEW RELEASES',
                    child: SizedBox(
                      height: 196,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: feed.newReleases.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final album = feed.newReleases[i];
                          return AlbumCard(
                            title: album.name,
                            subtitle: album.artistName ?? '',
                            artworkUrl: album.artworkUrl,
                            onTap: () => context.push('/album/${album.id}'),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (feed.featuredPlaylists.isNotEmpty) ...[
                  _Section(
                    title: 'FEATURED PLAYLISTS',
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: feed.featuredPlaylists.length.clamp(0, 6),
                      itemBuilder: (context, i) {
                        final pl = feed.featuredPlaylists[i];
                        return PlaylistCard(
                          name: pl.name,
                          artworkUrl: pl.artworkUrl,
                          onTap: () => context.push('/playlist/${pl.id}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (feed.popularArtists.isNotEmpty) ...[
                  _Section(
                    title: 'POPULAR ARTISTS',
                    child: SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: feed.popularArtists.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, i) {
                          final artist = feed.popularArtists[i];
                          return ArtistCircle(
                            name: artist.name,
                            imageUrl: artist.imageUrl,
                            onTap: () => context.push('/artist/${artist.id}'),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // ── Mood Playlists ───────────────────────────────
                _Section(
                  title: 'MOODS & MOMENTS',
                  child: _MoodChips(),
                ),
                const SizedBox(height: 80), // bottom padding for mini player
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SliverAppBar(
      floating: true,
      snap: true,
      title: Text(greeting, style: KaivaTextStyles.headlineLarge),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.go('/search'),
          tooltip: 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Future<void> _playSong(WidgetRef ref, List<Song> songs, int index) async {
    final handler = ref.read(audioHandlerProvider);
    // Put the tapped song first in the refresh queue so playback starts fast
    final reordered = [songs[index], ...songs.sublist(0, index), ...songs.sublist(index + 1)];
    final fresh = await fetchFreshQueue(reordered);
    // Re-map back: fresh[0] is the tapped song at position 0 of new queue
    await handler.playQueue(fresh, 0);
  }
}

// ── Section header + content ──────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(title, style: KaivaTextStyles.sectionHeader),
        ),
        child,
      ],
    );
  }
}

// ── Horizontal song cards ─────────────────────────────────────
class _HorizontalSongs extends StatelessWidget {
  final List<Song> songs;
  final void Function(Song, int) onTap;

  const _HorizontalSongs({required this.songs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SongCard(
          song: songs[i],
          onTap: () => onTap(songs[i], i),
        ),
      ),
    );
  }
}

// ── Mood playlists ────────────────────────────────────────────
typedef _Mood = ({String label, IconData icon, Color color, String searchQuery});

class _MoodChips extends StatelessWidget {
  static const List<_Mood> _moods = [
    (label: 'Morning', icon: Icons.wb_sunny_outlined, color: Color(0xFFFF9800), searchQuery: 'morning vibes'),
    (label: 'Workout', icon: Icons.fitness_center_rounded, color: Color(0xFFE53935), searchQuery: 'workout energy'),
    (label: 'Focus', icon: Icons.self_improvement_rounded, color: Color(0xFF42A5F5), searchQuery: 'focus study'),
    (label: 'Chill', icon: Icons.waves_rounded, color: Color(0xFF26C6DA), searchQuery: 'chill relax'),
    (label: 'Party', icon: Icons.celebration_rounded, color: Color(0xFFAB47BC), searchQuery: 'party hits'),
    (label: 'Sleep', icon: Icons.bedtime_outlined, color: Color(0xFF5C6BC0), searchQuery: 'sleep calm'),
    (label: 'Romance', icon: Icons.favorite_outline_rounded, color: Color(0xFFEC407A), searchQuery: 'romantic love'),
    (label: 'Devotional', icon: Icons.temple_hindu_outlined, color: Color(0xFFFF7043), searchQuery: 'devotional bhajan'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final mood = _moods[i];
          return GestureDetector(
            onTap: () => context.push(
              '/search/results?q=${Uri.encodeComponent(mood.searchQuery)}',
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mood.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: mood.color.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mood.icon, size: 14, color: mood.color),
                  const SizedBox(width: 6),
                  Text(
                    mood.label,
                    style: KaivaTextStyles.chipLabel.copyWith(color: mood.color),
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

// ── Shimmer placeholder for entire feed ───────────────────────
class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerHorizontalList(),
        SizedBox(height: 24),
        ShimmerHorizontalList(),
        SizedBox(height: 24),
        ShimmerHorizontalList(),
      ],
    );
  }
}
