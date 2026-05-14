import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../core/utils/song_loader.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/waveform_animation.dart';
import 'search_provider.dart';
import 'widgets/search_song_tile.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  bool _isActive    = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    setState(() => _isActive = q.isNotEmpty);
    ref.read(searchQueryProvider.notifier).state = q;
    ref.read(searchResultsProvider.notifier).search(q);
  }

  void _submitQuery(String q) {
    if (q.trim().isEmpty) return;
    _focusNode.unfocus();
    context.push('/search/results?q=${Uri.encodeComponent(q.trim())}');
  }

  void _clearSearch() {
    _controller.clear();
    _onQueryChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchResultsProvider);
    final recent      = ref.watch(recentSearchSongsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onSubmitted: _submitQuery,
              onClear: _clearSearch,
              isActive: _isActive,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !_isActive
                    ? _IdleView(
                        key: const ValueKey('idle'),
                        recentSongs: recent,
                        onRecentSongTap: (song) async {
                          ref.read(recentSearchSongsProvider.notifier).add(song);
                          final fresh = await fetchFreshQueue([song]);
                          ref.read(audioHandlerProvider).playQueue(fresh, 0);
                        },
                        onRecentDelete: (id) =>
                            ref.read(recentSearchSongsProvider.notifier).remove(id),
                        onClearAll: () =>
                            ref.read(recentSearchSongsProvider.notifier).clear(),
                      )
                    : searchState.when(
                        data: (result) {
                          if (result == null) return const SizedBox.shrink();
                          final songs = result.songs;
                          if (songs.isEmpty &&
                              result.albums.isEmpty &&
                              result.artists.isEmpty &&
                              result.playlists.isEmpty) {
                            return _EmptyResults(query: _controller.text);
                          }
                          return _QuickResults(
                            key: ValueKey(_controller.text),
                            songs: songs,
                            query: _controller.text,
                            onShowAll: () => _submitQuery(_controller.text),
                          );
                        },
                        loading: () => const _SearchShimmer(key: ValueKey('loading')),
                        error: (_, __) => const _SearchError(key: ValueKey('error')),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool isActive;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: KaivaTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Songs, artists, albums…',
          hintStyle: KaivaTextStyles.bodyMedium.copyWith(
            color: KaivaColors.textMuted,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: KaivaColors.textMuted),
          suffixIcon: isActive
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: KaivaColors.textMuted),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: KaivaColors.backgroundTertiary,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Idle: recent songs ────────────────────────────────────────
class _IdleView extends StatelessWidget {
  final List<Song> recentSongs;
  final ValueChanged<Song> onRecentSongTap;
  final ValueChanged<String> onRecentDelete;
  final VoidCallback onClearAll;

  const _IdleView({
    super.key,
    required this.recentSongs,
    required this.onRecentSongTap,
    required this.onRecentDelete,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 48, color: KaivaColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Songs you play from search\nwill appear here',
              style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent', style: KaivaTextStyles.sectionHeader),
            TextButton(
              onPressed: onClearAll,
              child: Text(
                'Clear all',
                style: KaivaTextStyles.bodySmall.copyWith(
                  color: KaivaColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        ...recentSongs.map(
          (song) => _RecentSongRow(
            song: song,
            onTap: () => onRecentSongTap(song),
            onDelete: () => onRecentDelete(song.id),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _RecentSongRow extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentSongRow({
    required this.song,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isCurrentSong = currentSong?.id == song.id;
    final isPlaying = isCurrentSong && ref.watch(isPlayingProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: song.artworkUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 44,
            height: 44,
            color: KaivaColors.backgroundTertiary,
            child: const Icon(Icons.music_note_rounded, size: 20, color: KaivaColors.textMuted),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 44,
            height: 44,
            color: KaivaColors.backgroundTertiary,
            child: const Icon(Icons.music_note_rounded, size: 20, color: KaivaColors.textMuted),
          ),
        ),
      ),
      title: Text(
        song.title,
        style: KaivaTextStyles.bodyMedium.copyWith(
          color: isCurrentSong ? KaivaColors.accentPrimary : KaivaColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textMuted),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCurrentSong
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WaveformAnimation(isPlaying: isPlaying),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: KaivaColors.textMuted),
                  onPressed: onDelete,
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: KaivaColors.textMuted),
              onPressed: onDelete,
            ),
      onTap: onTap,
    );
  }
}

// ── Quick results (top songs inline, "See all" → full results) ─
class _QuickResults extends StatelessWidget {
  final List songs;
  final String query;
  final VoidCallback onShowAll;

  const _QuickResults({
    super.key,
    required this.songs,
    required this.query,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (songs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Top Songs', style: KaivaTextStyles.sectionHeader),
          ),
          ...songs.take(5).map(
                (song) => SearchSongTile(song: song),
              ),
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: onShowAll,
            icon: const Icon(Icons.open_in_full_rounded, size: 16),
            label: Text('See all results for "$query"'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KaivaColors.accentPrimary,
              side: const BorderSide(color: KaivaColors.accentPrimary, width: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Shimmer while searching ───────────────────────────────────
class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, __) => const ShimmerSongTile(),
    );
  }
}

// ── No results ────────────────────────────────────────────────
class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: KaivaColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Network error ─────────────────────────────────────────────
class _SearchError extends StatelessWidget {
  const _SearchError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: KaivaColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Could not reach server.\nCheck your connection.',
            style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
