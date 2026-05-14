import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/local_playlist.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import 'library_provider.dart';
import 'widgets/create_playlist_sheet.dart';

// ── View mode toggle ──────────────────────────────────────────
enum _ViewMode { list, grid }

final _viewModeProvider = StateProvider<_ViewMode>((_) => _ViewMode.list);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter   = ref.watch(libraryFilterProvider);
    final viewMode = ref.watch(_viewModeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverToBoxAdapter(
            child: _FilterRow(
              selected: filter,
              viewMode: viewMode,
              onSelect: (f) {
                HapticFeedback.selectionClick();
                ref.read(libraryFilterProvider.notifier).state = f;
              },
              onToggleView: () {
                HapticFeedback.selectionClick();
                ref.read(_viewModeProvider.notifier).state =
                    viewMode == _ViewMode.list ? _ViewMode.grid : _ViewMode.list;
              },
            ),
          ),
          _SortRow(),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          _buildBody(context, ref, filter, viewMode),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      snap: true,
      titleSpacing: 16,
      title: const Text('Your Library', style: KaivaTextStyles.headlineLarge),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search library',
          onPressed: () => context.go('/search'),
        ),
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Create playlist',
          onPressed: () => _showCreatePlaylist(context, ref),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    LibraryFilter filter,
    _ViewMode viewMode,
  ) {
    switch (filter) {
      case LibraryFilter.playlists:
        return _PlaylistsSliver(viewMode: viewMode);
      case LibraryFilter.artists:
        return _ArtistsSliver();
      case LibraryFilter.albums:
        return _AlbumsSliver(viewMode: viewMode);
      case LibraryFilter.liked:
        return _LikedSongsSliver();
      case LibraryFilter.all:
        return _AllSliver(viewMode: viewMode);
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

// ── Filter chips + view toggle row ────────────────────────────
class _FilterRow extends StatelessWidget {
  final LibraryFilter selected;
  final _ViewMode viewMode;
  final ValueChanged<LibraryFilter> onSelect;
  final VoidCallback onToggleView;

  const _FilterRow({
    required this.selected,
    required this.viewMode,
    required this.onSelect,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Chip(
                    label: 'Playlists',
                    isSelected: selected == LibraryFilter.playlists,
                    onTap: () => onSelect(
                      selected == LibraryFilter.playlists
                          ? LibraryFilter.all
                          : LibraryFilter.playlists,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Albums',
                    isSelected: selected == LibraryFilter.albums,
                    onTap: () => onSelect(
                      selected == LibraryFilter.albums
                          ? LibraryFilter.all
                          : LibraryFilter.albums,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Artists',
                    isSelected: selected == LibraryFilter.artists,
                    onTap: () => onSelect(
                      selected == LibraryFilter.artists
                          ? LibraryFilter.all
                          : LibraryFilter.artists,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              viewMode == _ViewMode.list
                  ? Icons.grid_view_rounded
                  : Icons.view_list_rounded,
              size: 20,
              color: KaivaColors.textSecondary,
            ),
            onPressed: onToggleView,
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? KaivaColors.textPrimary
              : KaivaColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: KaivaTextStyles.chipLabel.copyWith(
            color: isSelected
                ? KaivaColors.backgroundPrimary
                : KaivaColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Sort row ──────────────────────────────────────────────────
class _SortRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(librarySortProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(librarySortProvider.notifier).state =
                sort == LibrarySortMode.recentlyAdded
                    ? LibrarySortMode.alphabetical
                    : LibrarySortMode.recentlyAdded;
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_vert_rounded,
                  size: 16, color: KaivaColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                sort == LibrarySortMode.recentlyAdded ? 'Recents' : 'A – Z',
                style: KaivaTextStyles.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── All view — Liked Songs + playlists + albums ───────────────
class _AllSliver extends ConsumerWidget {
  final _ViewMode viewMode;
  const _AllSliver({required this.viewMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked     = ref.watch(likedSongsProvider);
    final playlists = ref.watch(localPlaylistsProvider);
    final sort      = ref.watch(librarySortProvider);

    return SliverList(
      delegate: SliverChildListDelegate([
        // Liked Songs pinned entry
        liked.when(
          data: (songs) => songs.isEmpty
              ? const SizedBox.shrink()
              : _LikedSongsEntry(count: songs.length),
          loading: () => const ShimmerSongTile(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Local playlists
        playlists.when(
          data: (pls) {
            final sorted = _sorted(pls, sort);
            if (viewMode == _ViewMode.grid) {
              return _PlaylistGrid(playlists: sorted);
            }
            return Column(
              children: sorted
                  .asMap()
                  .entries
                  .map((e) => _PlaylistEntry(playlist: e.value)
                      .animate(delay: Duration(milliseconds: 30 * e.key))
                      .fadeIn(duration: 200.ms))
                  .toList(),
            );
          },
          loading: () =>
              Column(children: List.generate(4, (_) => const ShimmerSongTile())),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 100),
      ]),
    );
  }

  List<LocalPlaylist> _sorted(List<LocalPlaylist> list, LibrarySortMode sort) {
    if (sort == LibrarySortMode.alphabetical) {
      return [...list]..sort((a, b) => a.name.compareTo(b.name));
    }
    return [...list]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}

// ── Playlists-only view ───────────────────────────────────────
class _PlaylistsSliver extends ConsumerWidget {
  final _ViewMode viewMode;
  const _PlaylistsSliver({required this.viewMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(localPlaylistsProvider);
    final sort      = ref.watch(librarySortProvider);
    final liked     = ref.watch(likedSongsProvider);

    return playlists.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerSongTile(),
          childCount: 6,
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (pls) {
        final sorted = [...pls];
        if (sort == LibrarySortMode.alphabetical) {
          sorted.sort((a, b) => a.name.compareTo(b.name));
        } else {
          sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        }

        final likedCount = liked.valueOrNull?.length ?? 0;

        if (viewMode == _ViewMode.grid) {
          return SliverToBoxAdapter(
            child: Column(
              children: [
                if (likedCount > 0) _LikedSongsEntry(count: likedCount),
                _PlaylistGrid(playlists: sorted),
                const SizedBox(height: 100),
              ],
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (likedCount > 0 && i == 0) {
                return _LikedSongsEntry(count: likedCount);
              }
              final idx = likedCount > 0 ? i - 1 : i;
              if (idx >= sorted.length) return const SizedBox(height: 100);
              return _PlaylistEntry(playlist: sorted[idx])
                  .animate(delay: Duration(milliseconds: 30 * idx))
                  .fadeIn(duration: 200.ms);
            },
            childCount: sorted.length + (likedCount > 0 ? 2 : 1),
          ),
        );
      },
    );
  }
}

// ── Artists view ──────────────────────────────────────────────
class _ArtistsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(topArtistsProvider);

    return artists.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerSongTile(),
          childCount: 6,
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (list) {
        if (list.isEmpty) {
          return const SliverFillRemaining(
            child: _EmptyLibrary(
              icon: Icons.people_outline_rounded,
              message: 'No listening history yet.\nPlay some songs to see your top artists.',
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == list.length) return const SizedBox(height: 100);
              final a = list[i];
              final mins = a.totalSeconds ~/ 60;
              final sub = mins >= 60
                  ? 'Artist • ${mins ~/ 60}h ${mins % 60}m listened'
                  : 'Artist • ${mins}m listened';
              return _LibraryListTile(
                leading: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: a.artworkUrl,
                    width: 56, height: 56, fit: BoxFit.cover,
                    placeholder: (_, __) => _iconBox(Icons.person_rounded, circle: true),
                    errorWidget: (_, __, ___) => _iconBox(Icons.person_rounded, circle: true),
                  ),
                ),
                title: a.artistName,
                subtitle: sub,
                onTap: () => context.push('/artist/${a.artistId}'),
              ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn(duration: 200.ms);
            },
            childCount: list.length + 1,
          ),
        );
      },
    );
  }
}

// ── Albums view ───────────────────────────────────────────────
class _AlbumsSliver extends ConsumerWidget {
  final _ViewMode viewMode;
  const _AlbumsSliver({required this.viewMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(dailyAlbumsProvider);

    return albums.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerSongTile(),
          childCount: 6,
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (list) {
        if (list.isEmpty) {
          return const SliverFillRemaining(
            child: _EmptyLibrary(
              icon: Icons.album_outlined,
              message: 'No albums played today yet.\nStart listening to see your daily mix.',
            ),
          );
        }

        if (viewMode == _ViewMode.grid) {
          return SliverToBoxAdapter(
            child: Column(
              children: [
                _AlbumGrid(albums: list),
                const SizedBox(height: 100),
              ],
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == list.length) return const SizedBox(height: 100);
              final a = list[i];
              return _LibraryListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: a.artworkUrl,
                    width: 56, height: 56, fit: BoxFit.cover,
                    placeholder: (_, __) => _iconBox(Icons.album_rounded),
                    errorWidget: (_, __, ___) => _iconBox(Icons.album_rounded),
                  ),
                ),
                title: a.albumName,
                subtitle: 'Album • ${a.playCount} track${a.playCount == 1 ? '' : 's'} today',
                onTap: () => context.push('/album/${a.albumId}'),
              ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn(duration: 200.ms);
            },
            childCount: list.length + 1,
          ),
        );
      },
    );
  }
}

// ── Liked songs view ──────────────────────────────────────────
class _LikedSongsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked    = ref.watch(likedSongsProvider);
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
              if (i == songs.length + 1) return const SizedBox(height: 100);
              if (i == 0) {
                return _LikedSongsHeader(songs: songs, sortMode: sortMode, ref: ref);
              }
              final song = songs[i - 1];
              final currentSong = ref.watch(currentSongProvider).valueOrNull;
              return _LibraryListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.artworkUrl,
                    width: 56, height: 56, fit: BoxFit.cover,
                    placeholder: (_, __) => _iconBox(Icons.music_note_rounded),
                    errorWidget: (_, __, ___) => _iconBox(Icons.music_note_rounded),
                  ),
                ),
                title: song.title,
                subtitle: song.artist,
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Play All',
              onTap: () => ref.read(audioHandlerProvider).playQueue(songs, 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              onTap: () => ref.read(audioHandlerProvider).playQueue(songs, 0),
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<LibrarySortMode>(
            icon: const Icon(Icons.sort_rounded, color: KaivaColors.textMuted, size: 20),
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

  const _ActionButton({required this.icon, required this.label, required this.onTap});

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

// ── Liked Songs pinned entry ──────────────────────────────────
class _LikedSongsEntry extends ConsumerWidget {
  final int count;
  const _LikedSongsEntry({required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LibraryListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4B3FA0), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.favorite_rounded, color: KaivaColors.textOnAccent, size: 28),
      ),
      title: 'Liked Songs',
      subtitle: 'Playlist • $count song${count == 1 ? '' : 's'}',
      isPinned: true,
      onTap: () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.liked,
    );
  }
}

// ── Playlist entry ────────────────────────────────────────────
class _PlaylistEntry extends StatelessWidget {
  final LocalPlaylist playlist;
  const _PlaylistEntry({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return _LibraryListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: playlist.coverSource != null
            ? CachedNetworkImage(
                imageUrl: playlist.coverSource!,
                width: 56, height: 56, fit: BoxFit.cover,
                placeholder: (_, __) => _iconBox(Icons.queue_music_outlined),
                errorWidget: (_, __, ___) => _iconBox(Icons.queue_music_outlined),
              )
            : _iconBox(Icons.queue_music_outlined),
      ),
      title: playlist.name,
      subtitle: 'Playlist • ${playlist.songCount} song${playlist.songCount == 1 ? '' : 's'}',
      onTap: () => context.push('/local-playlist/${playlist.id}'),
    );
  }
}

// ── Shared list tile ──────────────────────────────────────────
class _LibraryListTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool isPinned;
  final bool isPlaying;
  final VoidCallback onTap;

  const _LibraryListTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPinned = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (isPinned) ...[
                        const Icon(Icons.push_pin_rounded,
                            size: 12, color: KaivaColors.accentPrimary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: KaivaTextStyles.titleMedium.copyWith(
                            color: isPlaying
                                ? KaivaColors.accentPrimary
                                : KaivaColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: KaivaTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Playlist grid ─────────────────────────────────────────────
class _PlaylistGrid extends StatelessWidget {
  final List<LocalPlaylist> playlists;
  const _PlaylistGrid({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, i) {
          final pl = playlists[i];
          return GestureDetector(
            onTap: () => context.push('/local-playlist/${pl.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: pl.coverSource != null
                        ? CachedNetworkImage(
                            imageUrl: pl.coverSource!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) =>
                                _iconBox(Icons.queue_music_outlined, size: double.infinity),
                            errorWidget: (_, __, ___) =>
                                _iconBox(Icons.queue_music_outlined, size: double.infinity),
                          )
                        : _iconBox(Icons.queue_music_outlined, size: double.infinity),
                  ),
                ),
                const SizedBox(height: 6),
                Text(pl.name,
                    style: KaivaTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${pl.songCount} songs',
                    style: KaivaTextStyles.bodySmall,
                    maxLines: 1),
              ],
            ),
          ).animate(delay: Duration(milliseconds: 40 * i)).fadeIn(duration: 200.ms);
        },
      ),
    );
  }
}

// ── Album grid ────────────────────────────────────────────────
class _AlbumGrid extends StatelessWidget {
  final List<DailyAlbumInfo> albums;
  const _AlbumGrid({required this.albums});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: albums.length,
        itemBuilder: (context, i) {
          final a = albums[i];
          return GestureDetector(
            onTap: () => context.push('/album/${a.albumId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: a.artworkUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) =>
                          _iconBox(Icons.album_rounded, size: double.infinity),
                      errorWidget: (_, __, ___) =>
                          _iconBox(Icons.album_rounded, size: double.infinity),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(a.albumName,
                    style: KaivaTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${a.playCount} tracks today',
                    style: KaivaTextStyles.bodySmall,
                    maxLines: 1),
              ],
            ),
          ).animate(delay: Duration(milliseconds: 40 * i)).fadeIn(duration: 200.ms);
        },
      ),
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
          Text(message,
              style: KaivaTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Shared icon placeholder box ───────────────────────────────
Widget _iconBox(IconData icon, {double size = 56.0, bool circle = false}) {
  return Container(
    width: size == double.infinity ? null : size,
    height: size == double.infinity ? null : size,
    decoration: BoxDecoration(
      color: KaivaColors.backgroundTertiary,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(4),
    ),
    child: Icon(icon, color: KaivaColors.textMuted, size: 24),
  );
}
