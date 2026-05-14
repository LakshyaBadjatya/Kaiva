import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/album.dart';
import '../../core/models/artist.dart';
import '../../core/models/playlist.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../shared/widgets/loading_shimmer.dart';
import 'search_provider.dart';
import 'widgets/search_song_tile.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = ['Songs', 'Albums', 'Artists', 'Playlists'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '"${widget.query}"',
          style: KaivaTextStyles.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: KaivaColors.accentPrimary,
          unselectedLabelColor: KaivaColors.textSecondary,
          indicatorColor: KaivaColors.accentPrimary,
          indicatorWeight: 2,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _SongsTab(query: widget.query),
          _AlbumsTab(query: widget.query),
          _ArtistsTab(query: widget.query),
          _PlaylistsTab(query: widget.query),
        ],
      ),
    );
  }
}

// ── Songs tab ─────────────────────────────────────────────────
class _SongsTab extends ConsumerStatefulWidget {
  final String query;
  const _SongsTab({required this.query});

  @override
  ConsumerState<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<_SongsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(pagedSongsProvider(widget.query).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(pagedSongsProvider(widget.query));
    final songs = state.items;

    if (songs.isEmpty && state.isLoading) {
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => const ShimmerSongTile(),
      );
    }
    if (songs.isEmpty) {
      return _EmptyTab(label: 'No songs found for "${widget.query}"');
    }

    return ListView.builder(
      controller: _scroll,
      itemCount: songs.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == songs.length) return const _LoadingFooter();
        final song = songs[i];
        return SearchSongTile(
          song: song,
          queue: songs,
          indexInQueue: i,
        );
      },
    );
  }
}

// ── Albums tab ────────────────────────────────────────────────
class _AlbumsTab extends ConsumerStatefulWidget {
  final String query;
  const _AlbumsTab({required this.query});

  @override
  ConsumerState<_AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends ConsumerState<_AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(pagedAlbumsProvider(widget.query).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(pagedAlbumsProvider(widget.query));
    final albums = state.items;

    if (albums.isEmpty && state.isLoading) {
      return const _GridShimmer();
    }
    if (albums.isEmpty) {
      return _EmptyTab(label: 'No albums found for "${widget.query}"');
    }

    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albums.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == albums.length) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return _AlbumGridItem(album: albums[i]);
      },
    );
  }
}

class _AlbumGridItem extends StatelessWidget {
  final Album album;
  const _AlbumGridItem({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/album/${album.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: album.highResArtworkUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(color: KaivaColors.backgroundTertiary),
                errorWidget: (_, __, ___) =>
                    Container(color: KaivaColors.backgroundTertiary,
                      child: const Icon(Icons.album_outlined, color: KaivaColors.textMuted)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.name,
            style: KaivaTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (album.artistName != null)
            Text(
              album.artistName!,
              style: KaivaTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ── Artists tab ───────────────────────────────────────────────
class _ArtistsTab extends ConsumerStatefulWidget {
  final String query;
  const _ArtistsTab({required this.query});

  @override
  ConsumerState<_ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends ConsumerState<_ArtistsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(pagedArtistsProvider(widget.query).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(pagedArtistsProvider(widget.query));
    final artists = state.items;

    if (artists.isEmpty && state.isLoading) {
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => const ShimmerSongTile(),
      );
    }
    if (artists.isEmpty) {
      return _EmptyTab(label: 'No artists found for "${widget.query}"');
    }

    return ListView.builder(
      controller: _scroll,
      itemCount: artists.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == artists.length) return const _LoadingFooter();
        return _ArtistListItem(artist: artists[i]);
      },
    );
  }
}

class _ArtistListItem extends StatelessWidget {
  final Artist artist;
  const _ArtistListItem({required this.artist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipOval(
        child: CachedNetworkImage(
          imageUrl: artist.highResImageUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(width: 52, height: 52, color: KaivaColors.backgroundTertiary),
          errorWidget: (_, __, ___) => Container(
            width: 52,
            height: 52,
            color: KaivaColors.backgroundTertiary,
            child: const Icon(Icons.person_outline, color: KaivaColors.textMuted),
          ),
        ),
      ),
      title: Text(artist.name, style: KaivaTextStyles.titleMedium),
      subtitle: artist.followerCount != null
          ? Text(
              '${_formatCount(artist.followerCount!)} followers',
              style: KaivaTextStyles.bodySmall,
            )
          : null,
      onTap: () => context.push('/artist/${artist.id}'),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return '$count';
  }
}

// ── Playlists tab ─────────────────────────────────────────────
class _PlaylistsTab extends ConsumerStatefulWidget {
  final String query;
  const _PlaylistsTab({required this.query});

  @override
  ConsumerState<_PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends ConsumerState<_PlaylistsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(pagedPlaylistsProvider(widget.query).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(pagedPlaylistsProvider(widget.query));
    final playlists = state.items;

    if (playlists.isEmpty && state.isLoading) {
      return const _GridShimmer();
    }
    if (playlists.isEmpty) {
      return _EmptyTab(label: 'No playlists found for "${widget.query}"');
    }

    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: playlists.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == playlists.length) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return _PlaylistGridItem(playlist: playlists[i]);
      },
    );
  }
}

class _PlaylistGridItem extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistGridItem({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/playlist/${playlist.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: playlist.highResArtworkUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(color: KaivaColors.backgroundTertiary),
                errorWidget: (_, __, ___) => Container(
                  color: KaivaColors.backgroundTertiary,
                  child: const Icon(Icons.queue_music_outlined, color: KaivaColors.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            playlist.name,
            style: KaivaTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${playlist.songCount} songs',
            style: KaivaTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  final String label;
  const _EmptyTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerCard(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 8,
      ),
    );
  }
}
