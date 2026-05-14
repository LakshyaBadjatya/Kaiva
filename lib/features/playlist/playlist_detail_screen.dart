import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/playlist.dart';
import '../../core/models/song.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';
import '../../features/library/library_provider.dart';
import '../../features/player/player_provider.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/song_tile.dart';

// Remote playlist provider
final remotePlaylistProvider =
    FutureProvider.family<Playlist, String>((ref, id) async {
  final response =
      await ApiClient.instance().get(ApiEndpoints.playlist(id));
  final data =
      (response.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?
          ?? {};
  return Playlist.fromJson(data);
});

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final bool isLocal;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLocal) return _LocalPlaylistView(playlistId: playlistId);
    return _RemotePlaylistView(playlistId: playlistId);
  }
}

// ── Remote playlist ───────────────────────────────────────────
class _RemotePlaylistView extends ConsumerWidget {
  final String playlistId;
  const _RemotePlaylistView({required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(remotePlaylistProvider(playlistId));

    return playlistAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView.builder(
          itemCount: 12,
          itemBuilder: (_, __) => const ShimmerSongTile(),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'Could not load playlist.',
            style: KaivaTextStyles.bodyMedium,
          ),
        ),
      ),
      data: (playlist) => _PlaylistScaffold(
        name: playlist.name,
        artworkUrl: playlist.highResArtworkUrl,
        description: playlist.description,
        songCount: playlist.songCount,
        songs: playlist.songs,
      ),
    );
  }
}

// ── Local playlist ────────────────────────────────────────────
class _LocalPlaylistView extends ConsumerWidget {
  final String playlistId;
  const _LocalPlaylistView({required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(localPlaylistSongsProvider(playlistId));
    final playlistsAsync = ref.watch(localPlaylistsProvider);

    final name = playlistsAsync.valueOrNull
            ?.firstWhere(
              (p) => p.id == playlistId,
              orElse: () => throw StateError('not found'),
            )
            .name ??
        'My Playlist';

    return songsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: ListView.builder(
          itemCount: 10,
          itemBuilder: (_, __) => const ShimmerSongTile(),
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: const Center(child: Text('Could not load songs.')),
      ),
      data: (songs) => _PlaylistScaffold(
        name: name,
        songs: songs,
        isLocal: true,
      ),
    );
  }
}

// ── Shared scaffold ───────────────────────────────────────────
class _PlaylistScaffold extends ConsumerWidget {
  final String name;
  final String? artworkUrl;
  final String? description;
  final int songCount;
  final List<Song> songs;
  final bool isLocal;

  const _PlaylistScaffold({
    required this.name,
    this.artworkUrl,
    this.description,
    this.songCount = 0,
    required this.songs,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: KaivaTextStyles.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: artworkUrl != null && artworkUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: artworkUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: KaivaColors.backgroundTertiary),
                      errorWidget: (_, __, ___) =>
                          Container(color: KaivaColors.backgroundTertiary),
                    )
                  : Container(
                      color: KaivaColors.backgroundTertiary,
                      child: const Icon(
                        Icons.queue_music_outlined,
                        size: 64,
                        color: KaivaColors.textMuted,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description != null && description!.isNotEmpty)
                          Text(description!, style: KaivaTextStyles.bodyMedium),
                        Text(
                          '${songs.length} song${songs.length == 1 ? '' : 's'}',
                          style: KaivaTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (songs.isNotEmpty)
                    FloatingActionButton.small(
                      backgroundColor: KaivaColors.accentPrimary,
                      foregroundColor: KaivaColors.textOnAccent,
                      onPressed: () =>
                          ref.read(audioHandlerProvider).playQueue(songs, 0),
                      child: const Icon(Icons.play_arrow_rounded),
                    ),
                ],
              ),
            ),
          ),
          if (songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No songs in this playlist.',
                  style: KaivaTextStyles.bodyMedium,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == songs.length) return const SizedBox(height: 80);
                  final song = songs[i];
                  return SongTile(
                    song: song,
                    isPlaying: currentSong?.id == song.id,
                    trackNumber: i + 1,
                    showArt: true,
                    onTap: () =>
                        ref.read(audioHandlerProvider).playQueue(songs, i),
                  );
                },
                childCount: songs.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}
