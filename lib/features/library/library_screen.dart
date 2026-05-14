import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/local_playlist.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/song_tile.dart';
import 'library_provider.dart';
import 'widgets/create_playlist_sheet.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(libraryFilterProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Library', style: KaivaTextStyles.headlineLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'New playlist',
                onPressed: () => _showCreatePlaylist(context, ref),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _FilterChips(
              selected: filter,
              onSelect: (f) => ref.read(libraryFilterProvider.notifier).state = f,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          _buildBody(context, ref, filter),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, LibraryFilter filter) {
    switch (filter) {
      case LibraryFilter.liked:
        return _LikedSongsSliver();
      case LibraryFilter.playlists:
        return _PlaylistsSliver();
      case LibraryFilter.all:
        return _AllSliver();
    }
  }

  void _showCreatePlaylist(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePlaylistSheet(),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final LibraryFilter selected;
  final ValueChanged<LibraryFilter> onSelect;

  const _FilterChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'All',
            isSelected: selected == LibraryFilter.all,
            onTap: () => onSelect(LibraryFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Liked',
            isSelected: selected == LibraryFilter.liked,
            onTap: () => onSelect(LibraryFilter.liked),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Playlists',
            isSelected: selected == LibraryFilter.playlists,
            onTap: () => onSelect(LibraryFilter.playlists),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KaivaColors.accentPrimary
              : KaivaColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected
                ? KaivaColors.accentPrimary
                : KaivaColors.borderDefault,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: KaivaTextStyles.chipLabel.copyWith(
            color: isSelected
                ? KaivaColors.textOnAccent
                : KaivaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── All content (liked + playlists) ──────────────────────────
class _AllSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likedSongsProvider);
    final playlists = ref.watch(localPlaylistsProvider);

    return SliverList(
      delegate: SliverChildListDelegate([
        // Liked Songs row
        liked.when(
          data: (songs) => songs.isEmpty
              ? const SizedBox.shrink()
              : _LikedSongsRow(count: songs.length),
          loading: () => const ShimmerSongTile(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Local playlists
        playlists.when(
          data: (pls) => Column(
            children: pls
                .map((pl) => _PlaylistRow(playlist: pl))
                .toList(),
          ),
          loading: () => Column(
            children: List.generate(3, (_) => const ShimmerSongTile()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }
}

// ── Liked songs section ───────────────────────────────────────
class _LikedSongsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likedSongsProvider);
    final sortMode = ref.watch(librarySortProvider);

    return liked.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerSongTile(),
          childCount: 10,
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (rawSongs) {
        if (rawSongs.isEmpty) {
          return const SliverFillRemaining(
            child: _EmptyLibrary(
              icon: Icons.favorite_border_rounded,
              message: 'No liked songs yet.\nTap ♥ on any song to save it here.',
            ),
          );
        }

        final songs = [...rawSongs];
        if (sortMode == LibrarySortMode.alphabetical) {
          songs.sort((a, b) => a.title.compareTo(b.title));
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              // Index 0 = action header, index 1..N = songs, last = spacer
              if (i == 0) {
                return _LikedSongsHeader(songs: songs, sortMode: sortMode, ref: ref);
              }
              if (i == songs.length + 1) return const SizedBox(height: 80);
              final song = songs[i - 1];
              final currentSong = ref.watch(currentSongProvider).valueOrNull;
              return SongTile(
                song: song,
                isPlaying: currentSong?.id == song.id,
                onTap: () => ref.read(audioHandlerProvider).playQueue(songs, i - 1),
              ).animate(delay: Duration(milliseconds: 30 * (i - 1))).fadeIn(duration: 200.ms);
            },
            childCount: songs.length + 2,
          ),
        );
      },
    );
  }
}

class _LikedSongsHeader extends StatelessWidget {
  final List<Song> songs;
  final LibrarySortMode sortMode;
  final WidgetRef ref;

  const _LikedSongsHeader({
    required this.songs,
    required this.sortMode,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          // Play All
          Expanded(
            child: _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Play All',
              onTap: () => ref.read(audioHandlerProvider).playQueue(songs, 0),
            ),
          ),
          const SizedBox(width: 10),
          // Shuffle All
          Expanded(
            child: _ActionButton(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              onTap: () async {
                final handler = ref.read(audioHandlerProvider);
                await handler.setShuffleMode(AudioServiceShuffleMode.all);
                await handler.playQueue(songs, 0);
              },
            ),
          ),
          const SizedBox(width: 10),
          // Sort button
          PopupMenuButton<LibrarySortMode>(
            icon: const Icon(
              Icons.sort_rounded,
              color: KaivaColors.textMuted,
              size: 20,
            ),
            color: KaivaColors.backgroundSecondary,
            onSelected: (mode) =>
                ref.read(librarySortProvider.notifier).state = mode,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: LibrarySortMode.recentlyAdded,
                child: Text(
                  'Recently Added',
                  style: KaivaTextStyles.bodyMedium.copyWith(
                    color: sortMode == LibrarySortMode.recentlyAdded
                        ? KaivaColors.accentPrimary
                        : KaivaColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuItem(
                value: LibrarySortMode.alphabetical,
                child: Text(
                  'A – Z',
                  style: KaivaTextStyles.bodyMedium.copyWith(
                    color: sortMode == LibrarySortMode.alphabetical
                        ? KaivaColors.accentPrimary
                        : KaivaColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: KaivaColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KaivaColors.borderSubtle, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: KaivaColors.accentPrimary),
            const SizedBox(width: 6),
            Text(label, style: KaivaTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }
}

// ── Playlists section ─────────────────────────────────────────
class _PlaylistsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(localPlaylistsProvider);

    return playlists.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerSongTile(),
          childCount: 5,
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (pls) {
        if (pls.isEmpty) {
          return const SliverFillRemaining(
            child: _EmptyLibrary(
              icon: Icons.queue_music_outlined,
              message: 'No playlists yet.\nTap + to create one.',
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == pls.length) return const SizedBox(height: 80);
              return _PlaylistRow(playlist: pls[i])
                  .animate(delay: Duration(milliseconds: 30 * i))
                  .fadeIn(duration: 200.ms);
            },
            childCount: pls.length + 1,
          ),
        );
      },
    );
  }
}

// ── Liked songs shortcut row ──────────────────────────────────
class _LikedSongsRow extends ConsumerWidget {
  final int count;
  const _LikedSongsRow({required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: KaivaColors.accentPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.favorite_rounded, color: KaivaColors.accentPrimary, size: 28),
      ),
      title: const Text('Liked Songs', style: KaivaTextStyles.titleMedium),
      subtitle: Text(
        '$count song${count == 1 ? '' : 's'}',
        style: KaivaTextStyles.bodySmall,
      ),
      onTap: () {
        ref.read(libraryFilterProvider.notifier).state = LibraryFilter.liked;
      },
    );
  }
}

// ── Playlist row ──────────────────────────────────────────────
class _PlaylistRow extends StatelessWidget {
  final LocalPlaylist playlist;
  const _PlaylistRow({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: playlist.coverSource != null
            ? CachedNetworkImage(
                imageUrl: playlist.coverSource!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                placeholder: (_, __) => _PlaceholderCover(),
                errorWidget: (_, __, ___) => _PlaceholderCover(),
              )
            : _PlaceholderCover(),
      ),
      title: Text(playlist.name, style: KaivaTextStyles.titleMedium),
      subtitle: Text(
        '${playlist.songCount} song${playlist.songCount == 1 ? '' : 's'}',
        style: KaivaTextStyles.bodySmall,
      ),
      onTap: () => context.push('/local-playlist/${playlist.id}'),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: KaivaColors.backgroundTertiary,
      child: const Icon(Icons.queue_music_outlined, color: KaivaColors.textMuted, size: 24),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyLibrary extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyLibrary({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: KaivaColors.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: KaivaTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
