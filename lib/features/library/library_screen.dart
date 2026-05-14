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
      case LibraryFilter.artists:
        return _TopArtistsSliver();
      case LibraryFilter.albums:
        return _DailyAlbumsSliver();
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
          _Chip(label: 'All',     isSelected: selected == LibraryFilter.all,      onTap: () => onSelect(LibraryFilter.all)),
          const SizedBox(width: 8),
          _Chip(label: 'Liked',   isSelected: selected == LibraryFilter.liked,    onTap: () => onSelect(LibraryFilter.liked)),
          const SizedBox(width: 8),
          _Chip(label: 'Playlists', isSelected: selected == LibraryFilter.playlists, onTap: () => onSelect(LibraryFilter.playlists)),
          const SizedBox(width: 8),
          _Chip(label: 'Artists', isSelected: selected == LibraryFilter.artists,  onTap: () => onSelect(LibraryFilter.artists)),
          const SizedBox(width: 8),
          _Chip(label: 'Albums',  isSelected: selected == LibraryFilter.albums,   onTap: () => onSelect(LibraryFilter.albums)),
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
          color: isSelected ? KaivaColors.accentPrimary : KaivaColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? KaivaColors.accentPrimary : KaivaColors.borderDefault,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: KaivaTextStyles.chipLabel.copyWith(
            color: isSelected ? KaivaColors.textOnAccent : KaivaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── All — shows liked shortcut, top artists, daily albums, playlists ──
class _AllSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked      = ref.watch(likedSongsProvider);
    final playlists  = ref.watch(localPlaylistsProvider);
    final artists    = ref.watch(topArtistsProvider);
    final albums     = ref.watch(dailyAlbumsProvider);

    return SliverList(
      delegate: SliverChildListDelegate([
        // Liked Songs shortcut
        liked.when(
          data: (songs) => songs.isEmpty
              ? const SizedBox.shrink()
              : _LikedSongsRow(count: songs.length),
          loading: () => const ShimmerSongTile(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Top Artists section
        artists.when(
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : _HorizontalSection(
                  title: 'Top Artists',
                  subtitle: 'Your most played',
                  onSeeAll: () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.artists,
                  children: list.map((a) => _ArtistCard(artist: a)).toList(),
                ),
          loading: () => _HorizontalShimmerSection(title: 'Top Artists'),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Daily Albums section
        albums.when(
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : _HorizontalSection(
                  title: 'In Your Daily Mix',
                  subtitle: 'Albums you played today',
                  onSeeAll: () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.albums,
                  children: list.map((a) => _AlbumCard(album: a)).toList(),
                ),
          loading: () => _HorizontalShimmerSection(title: 'In Your Daily Mix'),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Local playlists
        playlists.when(
          data: (pls) => pls.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Playlists', onSeeAll: null),
                    ...pls.map((pl) => _PlaylistRow(playlist: pl)),
                  ],
                ),
          loading: () => Column(children: List.generate(3, (_) => const ShimmerSongTile())),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 80),
      ]),
    );
  }
}

// ── Horizontal section wrapper ────────────────────────────────
class _HorizontalSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;
  final List<Widget> children;

  const _HorizontalSection({
    required this.title,
    required this.subtitle,
    required this.children,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle, onSeeAll: onSeeAll),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => children[i]
                .animate(delay: Duration(milliseconds: 40 * i))
                .fadeIn(duration: 200.ms)
                .slideX(begin: 0.1, end: 0),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _HorizontalShimmerSection extends StatelessWidget {
  final String title;
  const _HorizontalShimmerSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, onSeeAll: null),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => const _ShimmerCard(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: KaivaColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KaivaTextStyles.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: KaivaTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: KaivaTextStyles.labelMedium.copyWith(
                  color: KaivaColors.accentPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Artist card ───────────────────────────────────────────────
class _ArtistCard extends StatelessWidget {
  final TopArtistInfo artist;

  const _ArtistCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    final mins = artist.totalSeconds ~/ 60;
    final label = mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '${mins}m';

    return GestureDetector(
      onTap: () => context.push('/artist/${artist.artistId}'),
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KaivaColors.borderSubtle, width: 1),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: artist.artworkUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: KaivaColors.backgroundTertiary,
                    child: const Icon(Icons.person_rounded,
                        color: KaivaColors.textMuted, size: 36),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: KaivaColors.backgroundTertiary,
                    child: const Icon(Icons.person_rounded,
                        color: KaivaColors.textMuted, size: 36),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.artistName,
              style: KaivaTextStyles.labelMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Album card ────────────────────────────────────────────────
class _AlbumCard extends StatelessWidget {
  final DailyAlbumInfo album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/album/${album.albumId}'),
      child: SizedBox(
        width: 104,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: album.artworkUrl,
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 104,
                  height: 104,
                  color: KaivaColors.backgroundTertiary,
                  child: const Icon(Icons.album_rounded,
                      color: KaivaColors.textMuted, size: 40),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 104,
                  height: 104,
                  color: KaivaColors.backgroundTertiary,
                  child: const Icon(Icons.album_rounded,
                      color: KaivaColors.textMuted, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              album.albumName,
              style: KaivaTextStyles.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${album.playCount} track${album.playCount == 1 ? '' : 's'} today',
              style: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textMuted),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Artists full-page sliver ──────────────────────────────
class _TopArtistsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(topArtistsProvider);

    return artists.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerSongTile(),
          childCount: 8,
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
              if (i == list.length) return const SizedBox(height: 80);
              final a = list[i];
              final mins = a.totalSeconds ~/ 60;
              final timeLabel = mins >= 60
                  ? '${mins ~/ 60}h ${mins % 60}m listened'
                  : '${mins}m listened';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: a.artworkUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 52, height: 52,
                      color: KaivaColors.backgroundTertiary,
                      child: const Icon(Icons.person_rounded, color: KaivaColors.textMuted),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 52, height: 52,
                      color: KaivaColors.backgroundTertiary,
                      child: const Icon(Icons.person_rounded, color: KaivaColors.textMuted),
                    ),
                  ),
                ),
                title: Text(a.artistName, style: KaivaTextStyles.titleMedium),
                subtitle: Text(timeLabel, style: KaivaTextStyles.bodySmall),
                trailing: Text(
                  '#${i + 1}',
                  style: KaivaTextStyles.headlineLarge.copyWith(
                    color: i == 0
                        ? KaivaColors.accentPrimary
                        : KaivaColors.textMuted,
                    fontSize: 18,
                  ),
                ),
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

// ── Daily Albums full-page sliver ─────────────────────────────
class _DailyAlbumsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(dailyAlbumsProvider);

    return albums.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerSongTile(),
          childCount: 8,
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
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == list.length) return const SizedBox(height: 80);
              final a = list[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: a.artworkUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 52, height: 52,
                      color: KaivaColors.backgroundTertiary,
                      child: const Icon(Icons.album_rounded, color: KaivaColors.textMuted),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 52, height: 52,
                      color: KaivaColors.backgroundTertiary,
                      child: const Icon(Icons.album_rounded, color: KaivaColors.textMuted),
                    ),
                  ),
                ),
                title: Text(a.albumName, style: KaivaTextStyles.titleMedium),
                subtitle: Text(
                  '${a.playCount} track${a.playCount == 1 ? '' : 's'} played today',
                  style: KaivaTextStyles.bodySmall,
                ),
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

// ── Liked songs section ───────────────────────────────────────
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
              if (i == 0) return _LikedSongsHeader(songs: songs, sortMode: sortMode, ref: ref);
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
              onTap: () async {
                final handler = ref.read(audioHandlerProvider);
                await handler.setShuffleMode(AudioServiceShuffleMode.all);
                await handler.playQueue(songs, 0);
              },
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<LibrarySortMode>(
            icon: const Icon(Icons.sort_rounded, color: KaivaColors.textMuted, size: 20),
            color: KaivaColors.backgroundSecondary,
            onSelected: (mode) => ref.read(librarySortProvider.notifier).state = mode,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: LibrarySortMode.recentlyAdded,
                child: Text('Recently Added',
                    style: KaivaTextStyles.bodyMedium.copyWith(
                      color: sortMode == LibrarySortMode.recentlyAdded
                          ? KaivaColors.accentPrimary
                          : KaivaColors.textPrimary,
                    )),
              ),
              PopupMenuItem(
                value: LibrarySortMode.alphabetical,
                child: Text('A – Z',
                    style: KaivaTextStyles.bodyMedium.copyWith(
                      color: sortMode == LibrarySortMode.alphabetical
                          ? KaivaColors.accentPrimary
                          : KaivaColors.textPrimary,
                    )),
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
      subtitle: Text('$count song${count == 1 ? '' : 's'}', style: KaivaTextStyles.bodySmall),
      onTap: () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.liked,
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
                width: 52, height: 52, fit: BoxFit.cover,
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
      width: 52, height: 52,
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
          Text(message, style: KaivaTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
